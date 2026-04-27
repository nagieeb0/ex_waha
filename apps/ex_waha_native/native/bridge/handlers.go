// Per-op handlers. Keep these focused — the dispatch loop in main.go
// invokes each in its own goroutine, so they may run concurrently.

package main

import (
	"context"
	"fmt"

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

