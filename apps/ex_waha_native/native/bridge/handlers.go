// Per-op handlers. Keep these focused — the dispatch loop in main.go
// invokes each in its own goroutine, so they may run concurrently.

package main

import (
	"context"
	"encoding/base64"
	"fmt"
	"io"
	"net/http"

	"go.mau.fi/whatsmeow"
	"go.mau.fi/whatsmeow/proto/waE2E"
	"go.mau.fi/whatsmeow/types"
	"google.golang.org/protobuf/proto"
)

func handleOpenSession(ctx context.Context, mgr *sessionManager, msg *frame) {
	store := parseStoreConfig(msg.Args)

	entry, err := mgr.open(ctx, msg.Session, store)
	if err != nil {
		reply(msg.Ref, false, nil, err.Error(), "open_failed")
		return
	}

	attachEventHandler(entry.client, msg.Session)

	if entry.client.Store.ID == nil {
		// Unpaired — start QR flow.
		qrChan, err := entry.client.GetQRChannel(ctx)
		if err != nil {
			reply(msg.Ref, false, nil, err.Error(), "qr_failed")
			return
		}

		if err := entry.client.Connect(); err != nil {
			reply(msg.Ref, false, nil, err.Error(), "connect_failed")
			return
		}

		go streamQR(msg.Session, qrChan)
		reply(msg.Ref, true, map[string]string{"status": "SCAN_QR"}, "", "")
		return
	}

	if err := entry.client.Connect(); err != nil {
		reply(msg.Ref, false, nil, err.Error(), "connect_failed")
		return
	}

	reply(msg.Ref, true, map[string]string{"status": "WORKING"}, "", "")
}

func streamQR(session string, qrChan <-chan whatsmeow.QRChannelItem) {
	for evt := range qrChan {
		switch evt.Event {
		case "code":
			emitEvent(session, "qr", map[string]string{"code": evt.Code})
		case "success":
			emitEvent(session, "qr_success", map[string]string{})
		case "timeout":
			emitEvent(session, "qr_timeout", map[string]string{})
		default:
			emitEvent(session, "qr_event", map[string]string{"event": evt.Event})
		}
	}
}

func handleCloseSession(mgr *sessionManager, msg *frame) {
	if err := mgr.close(msg.Session); err != nil {
		reply(msg.Ref, false, nil, err.Error(), "close_failed")
		return
	}
	reply(msg.Ref, true, map[string]bool{"closed": true}, "", "")
}

func handleSendText(ctx context.Context, mgr *sessionManager, msg *frame) {
	entry, ok := mgr.get(msg.Session)
	if !ok {
		reply(msg.Ref, false, nil, "session not open", "not_started")
		return
	}

	to, _ := msg.Args["to"].(string)
	text, _ := msg.Args["text"].(string)

	jid, err := types.ParseJID(to)
	if err != nil {
		reply(msg.Ref, false, nil, fmt.Sprintf("bad jid %q: %v", to, err), "invalid_recipient")
		return
	}

	resp, err := entry.client.SendMessage(ctx, jid, &waE2E.Message{
		Conversation: proto.String(text),
	})
	if err != nil {
		reply(msg.Ref, false, nil, err.Error(), "send_failed")
		return
	}

	reply(msg.Ref, true, map[string]interface{}{
		"id":        resp.ID,
		"timestamp": resp.Timestamp.Unix(),
	}, "", "")
}

// handleSendMedia uploads media bytes (from a URL or base64-encoded data) to
// WhatsApp's media servers and dispatches the corresponding typed message.
//
// Args shape (from ExWahaNative.Provider.send_media/4):
//
//	{
//	  "to":   "<digits>@s.whatsapp.net",
//	  "type": "image" | "video" | "audio" | "document",
//	  "media": {
//	    "file":     {"url": "...", "data": "<base64>", "filename": "...", "mimetype": "..."},
//	    "caption":  "...",
//	    "filename": "..."
//	  }
//	}
func handleSendMedia(ctx context.Context, mgr *sessionManager, msg *frame) {
	entry, ok := mgr.get(msg.Session)
	if !ok {
		reply(msg.Ref, false, nil, "session not open", "not_started")
		return
	}

	to, _ := msg.Args["to"].(string)
	mtype, _ := msg.Args["type"].(string)
	media, _ := msg.Args["media"].(map[string]interface{})
	if media == nil {
		reply(msg.Ref, false, nil, "media is required", "invalid_args")
		return
	}

	jid, err := types.ParseJID(to)
	if err != nil {
		reply(msg.Ref, false, nil, fmt.Sprintf("bad jid %q: %v", to, err), "invalid_recipient")
		return
	}

	wmType, err := whatsmeowMediaType(mtype)
	if err != nil {
		reply(msg.Ref, false, nil, err.Error(), "invalid_args")
		return
	}

	data, mimetype, filename, err := resolveMediaBytes(ctx, media)
	if err != nil {
		reply(msg.Ref, false, nil, err.Error(), "invalid_args")
		return
	}

	uploaded, err := entry.client.Upload(ctx, data, wmType)
	if err != nil {
		reply(msg.Ref, false, nil, err.Error(), "upload_failed")
		return
	}

	caption, _ := media["caption"].(string)
	if fn, ok := media["filename"].(string); ok && fn != "" {
		filename = fn
	}

	wmsg := buildMediaMessage(mtype, uploaded, uint64(len(data)), mimetype, filename, caption)
	if wmsg == nil {
		reply(msg.Ref, false, nil, "could not build message", "invalid_args")
		return
	}

	resp, err := entry.client.SendMessage(ctx, jid, wmsg)
	if err != nil {
		reply(msg.Ref, false, nil, err.Error(), "send_failed")
		return
	}

	reply(msg.Ref, true, map[string]interface{}{
		"id":        resp.ID,
		"timestamp": resp.Timestamp.Unix(),
	}, "", "")
}

// resolveMediaBytes returns (bytes, mimetype, filename) given the `file` sub-map.
// Accepts either {"url": "..."} (HTTP fetched) or {"data": "<base64>"}.
func resolveMediaBytes(ctx context.Context, media map[string]interface{}) ([]byte, string, string, error) {
	file, _ := media["file"].(map[string]interface{})
	if file == nil {
		return nil, "", "", fmt.Errorf("media.file is required")
	}

	mimetype, _ := file["mimetype"].(string)
	filename, _ := file["filename"].(string)

	if url, ok := file["url"].(string); ok && url != "" {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			return nil, "", "", fmt.Errorf("build request: %w", err)
		}
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			return nil, "", "", fmt.Errorf("download %s: %w", url, err)
		}
		defer resp.Body.Close()
		if resp.StatusCode/100 != 2 {
			return nil, "", "", fmt.Errorf("download %s: HTTP %s", url, resp.Status)
		}
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			return nil, "", "", fmt.Errorf("read body: %w", err)
		}
		if mimetype == "" {
			mimetype = resp.Header.Get("Content-Type")
		}
		return body, mimetype, filename, nil
	}

	if data, ok := file["data"].(string); ok && data != "" {
		decoded, err := base64.StdEncoding.DecodeString(data)
		if err != nil {
			return nil, "", "", fmt.Errorf("decode base64: %w", err)
		}
		return decoded, mimetype, filename, nil
	}

	return nil, "", "", fmt.Errorf("media.file requires url or data")
}

func whatsmeowMediaType(t string) (whatsmeow.MediaType, error) {
	switch t {
	case "image":
		return whatsmeow.MediaImage, nil
	case "video":
		return whatsmeow.MediaVideo, nil
	case "audio":
		return whatsmeow.MediaAudio, nil
	case "document":
		return whatsmeow.MediaDocument, nil
	default:
		return "", fmt.Errorf("unknown media type %q", t)
	}
}

func buildMediaMessage(t string, up whatsmeow.UploadResponse, size uint64, mimetype, filename, caption string) *waE2E.Message {
	captionPtr := optionalString(caption)
	switch t {
	case "image":
		return &waE2E.Message{ImageMessage: &waE2E.ImageMessage{
			URL:           proto.String(up.URL),
			DirectPath:    proto.String(up.DirectPath),
			MediaKey:      up.MediaKey,
			Mimetype:      proto.String(orDefault(mimetype, "image/jpeg")),
			FileEncSHA256: up.FileEncSHA256,
			FileSHA256:    up.FileSHA256,
			FileLength:    proto.Uint64(size),
			Caption:       captionPtr,
		}}
	case "video":
		return &waE2E.Message{VideoMessage: &waE2E.VideoMessage{
			URL:           proto.String(up.URL),
			DirectPath:    proto.String(up.DirectPath),
			MediaKey:      up.MediaKey,
			Mimetype:      proto.String(orDefault(mimetype, "video/mp4")),
			FileEncSHA256: up.FileEncSHA256,
			FileSHA256:    up.FileSHA256,
			FileLength:    proto.Uint64(size),
			Caption:       captionPtr,
		}}
	case "audio":
		return &waE2E.Message{AudioMessage: &waE2E.AudioMessage{
			URL:           proto.String(up.URL),
			DirectPath:    proto.String(up.DirectPath),
			MediaKey:      up.MediaKey,
			Mimetype:      proto.String(orDefault(mimetype, "audio/ogg; codecs=opus")),
			FileEncSHA256: up.FileEncSHA256,
			FileSHA256:    up.FileSHA256,
			FileLength:    proto.Uint64(size),
		}}
	case "document":
		return &waE2E.Message{DocumentMessage: &waE2E.DocumentMessage{
			URL:           proto.String(up.URL),
			DirectPath:    proto.String(up.DirectPath),
			MediaKey:      up.MediaKey,
			Mimetype:      proto.String(orDefault(mimetype, "application/pdf")),
			FileEncSHA256: up.FileEncSHA256,
			FileSHA256:    up.FileSHA256,
			FileLength:    proto.Uint64(size),
			FileName:      optionalString(filename),
			Caption:       captionPtr,
		}}
	}
	return nil
}

func orDefault(s, fallback string) string {
	if s == "" {
		return fallback
	}
	return s
}

func optionalString(s string) *string {
	if s == "" {
		return nil
	}
	return proto.String(s)
}

func handleLogout(ctx context.Context, mgr *sessionManager, msg *frame) {
	entry, ok := mgr.get(msg.Session)
	if !ok {
		reply(msg.Ref, false, nil, "session not open", "not_started")
		return
	}

	if err := entry.client.Logout(ctx); err != nil {
		reply(msg.Ref, false, nil, err.Error(), "logout_failed")
		return
	}

	_ = mgr.close(msg.Session)
	reply(msg.Ref, true, map[string]bool{"logged_out": true}, "", "")
}

func handleRequestPairingCode(ctx context.Context, mgr *sessionManager, msg *frame) {
	entry, ok := mgr.get(msg.Session)
	if !ok {
		reply(msg.Ref, false, nil, "session not open", "not_started")
		return
	}

	phone, _ := msg.Args["phone"].(string)
	if phone == "" {
		reply(msg.Ref, false, nil, "phone is required", "invalid_args")
		return
	}

	code, err := entry.client.PairPhone(ctx, phone, true, 0, "Chrome (Linux)")
	if err != nil {
		reply(msg.Ref, false, nil, err.Error(), "pair_failed")
		return
	}

	reply(msg.Ref, true, map[string]string{"code": code}, "", "")
}

