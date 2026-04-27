# Changelog

## [0.2.0] - 2026-04-27

### Added
- Real `whatsmeow` integration in the Go bridge: `open_session`, QR
  pairing flow, phone-pairing-code flow, `send_text`, `logout`,
  `close_session`.
- Event mapping from whatsmeow to the bridge protocol — `qr`, `paired`,
  `connected`, `disconnected`, `logged_out`, `message`, `message_ack`,
  `offline_sync_completed`.
- SQLite session persistence via `modernc.org/sqlite` (pure Go, no CGo).
  In-memory store available via `:memory` for tests.
- `ExWahaNative.Session.qr/1` — read latest QR string from the session.
- `ExWahaNative.Session.request_pairing_code/2` — link without QR.
- `ExWahaNative.Session.logout/1` — invalidate the WhatsApp pairing.
- `ExWahaNative.Session.stop/1` — close the local session without logging
  out.
- `examples/03_send_via_native.exs` — end-to-end pair + send walkthrough.

### Changed
- Go module updated to `whatsmeow v0.0.0-20260421083005-5b8886176ff7`,
  `modernc.org/sqlite v1.50.0`, `google.golang.org/protobuf v1.36.11`.
- README marked 0.2.0 status; usage section now reflects the working
  pairing/send flow.

## [0.1.0] - 2026-04-27

### Added
- `ExWahaNative.Wire` — length-prefixed JSON framing for the Elixir <-> Go
  bridge protocol with stream decoding and request-correlation refs.
- `ExWahaNative.Bridge` — Port-owning GenServer that manages the Go process,
  serializes outbound requests, correlates responses, dispatches async
  events to the right Session.
- `ExWahaNative.Session` — per-account GenServer holding status, QR, and
  subscribers; routes outbound calls through the Bridge.
- `ExWahaNative.Session.{Registry, Supervisor}` — registry + dynamic
  supervisor for Session processes.
- `ExWahaNative.Account` — account struct identifying a session and its
  store backend.
- `ExWahaNative.Provider` — implements `ExWaha.Provider` so calls go through
  the unified facade.
- `Mix.Tasks.ExWahaNative.BuildNative` — `mix ex_waha_native.build_native`
  compiles the Go bridge binary with optional `--target` cross-compilation.
- Go bridge skeleton (`native/bridge/main.go`) — stdio loop, JSON framing,
  `ping` handler, stub handlers for the planned ops.

### Known limitations
- `whatsmeow` is not yet integrated on the Go side. All ops except `ping`
  return `{"ok": false, "code": "not_implemented"}`. Wiring is the focus
  of 0.2.0.
- `ExWahaNative.Provider.parse_event/2` and `verify_signature/3` are
  stubs — events flow over the bridge directly, not through HTTP webhooks.
