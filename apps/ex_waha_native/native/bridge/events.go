// Bridge between whatsmeow event types and the JSON event protocol.

package main

import (
	"go.mau.fi/whatsmeow"
	"go.mau.fi/whatsmeow/types/events"
)

// attachEventHandler wires the client's event stream to emitEvent calls
// scoped to the given session id.
func attachEventHandler(client *whatsmeow.Client, sessionID string) {
	client.AddEventHandler(func(evt interface{}) {
		switch v := evt.(type) {
		case *events.PairSuccess:
			emitEvent(sessionID, "paired", map[string]interface{}{
				"phone":      v.ID.User,
				"device":     v.ID.String(),
				"business":   v.BusinessName,
				"platform":   v.Platform,
			})

		case *events.Connected:
			emitEvent(sessionID, "connected", map[string]interface{}{})

		case *events.Disconnected:
			emitEvent(sessionID, "disconnected", map[string]interface{}{})

		case *events.LoggedOut:
			emitEvent(sessionID, "logged_out", map[string]interface{}{
				"reason": v.Reason.String(),
			})

		case *events.Message:
			emitEvent(sessionID, "message", encodeMessage(v))

		case *events.Receipt:
			emitEvent(sessionID, "message_ack", encodeReceipt(v))

		case *events.OfflineSyncCompleted:
			emitEvent(sessionID, "offline_sync_completed", map[string]interface{}{
				"count": v.Count,
			})
		}
	})
}

func encodeMessage(m *events.Message) map[string]interface{} {
	out := map[string]interface{}{
		"id":        m.Info.ID,
		"from":      m.Info.Sender.String(),
		"chat":      m.Info.Chat.String(),
		"timestamp": m.Info.Timestamp.Unix(),
		"is_group":  m.Info.IsGroup,
		"push_name": m.Info.PushName,
	}

	if msg := m.Message; msg != nil {
		switch {
		case msg.Conversation != nil:
			out["body"] = msg.GetConversation()
			out["type"] = "text"

		case msg.ExtendedTextMessage != nil:
			out["body"] = msg.GetExtendedTextMessage().GetText()
			out["type"] = "text"

		case msg.ImageMessage != nil:
			out["type"] = "image"
			out["caption"] = msg.GetImageMessage().GetCaption()

		case msg.VideoMessage != nil:
			out["type"] = "video"
			out["caption"] = msg.GetVideoMessage().GetCaption()

		case msg.AudioMessage != nil:
			out["type"] = "audio"

		case msg.DocumentMessage != nil:
			out["type"] = "document"
			out["filename"] = msg.GetDocumentMessage().GetFileName()

		case msg.LocationMessage != nil:
			out["type"] = "location"
			loc := msg.GetLocationMessage()
			out["lat"] = loc.GetDegreesLatitude()
			out["lng"] = loc.GetDegreesLongitude()
		}
	}

	return out
}

func encodeReceipt(r *events.Receipt) map[string]interface{} {
	ids := make([]string, 0, len(r.MessageIDs))
	for _, id := range r.MessageIDs {
		ids = append(ids, string(id))
	}

	return map[string]interface{}{
		"chat":        r.Chat.String(),
		"sender":      r.Sender.String(),
		"timestamp":   r.Timestamp.Unix(),
		"message_ids": ids,
		"type":        string(r.Type),
	}
}
