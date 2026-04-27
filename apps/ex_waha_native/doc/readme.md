# ExWahaNative

[![Hex.pm](https://img.shields.io/hexpm/v/ex_waha_native.svg)](https://hex.pm/packages/ex_waha_native)
[![Documentation](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_waha_native)

Native [`ex_waha`](https://hex.pm/packages/ex_waha) provider that talks the
WhatsApp Multi-Device protocol directly via [`whatsmeow`](https://github.com/tulir/whatsmeow)
(Go), running as a single supervised sidecar process inside your BEAM node.
**No WAHA Docker container required.**

> **Status: 0.2.0 wires whatsmeow into the Go side.** The bridge now opens
> real WhatsApp sessions through `go.mau.fi/whatsmeow`, supports QR pairing
> and phone pairing codes, sends text, emits `qr` / `paired` / `connected`
> / `message` / `message_ack` events, and persists devices in SQLite. See
> the [Roadmap](#roadmap) for what's next.

## Why this exists

`:ex_waha` (the wrapper) requires running the WAHA Docker container as a
sidecar. That works but means an extra service to deploy, monitor, and
restart. `:ex_waha_native` replaces WAHA with a Go binary in your release's
`priv/` directory:

```
your_app release
└── priv/
    └── ex_waha_native/
        └── native/
            └── whatsmeow_bridge          # statically-linked Go binary
                                           # one process per BEAM node
```

One binary, no HTTP, no Docker. Sessions live in SQLite (per session) or
Postgres (shared) via whatsmeow's sqlstore.

## Installation

```elixir
def deps do
  [
    {:ex_waha, "~> 0.1.0"},
    {:ex_waha_native, "~> 0.1.0"}
  ]
end
```

You also need the **Go toolchain** (≥ 1.21) on the build machine. After
`mix deps.get`:

```bash
mix ex_waha_native.build_native
```

This compiles `native/bridge/*.go` to `priv/native/whatsmeow_bridge`.
Cross-compile for your deploy target with `--target linux/amd64`.

## Usage

```elixir
# Tell the application to start the bridge GenServer
config :ex_waha_native, start_bridge: true

# Build an account
account = %ExWahaNative.Account{
  session: "profile_42",
  store: {:sqlite, "priv/sessions/profile_42.db"},
  bridge: ExWahaNative.Bridge
}

# Bring under supervision (spawns the whatsmeow client, emits QR via event)
{:ok, _pid} = ExWahaNative.Session.Supervisor.ensure_started(account)

# Subscribe to events for this session
ExWahaNative.Session.subscribe(account)

# First time: render the QR. Subsequent runs reconnect from sqlstore.
receive do
  {:ex_waha_native, :qr, %{"code" => code}} -> render_qr(code)
end

receive do
  {:ex_waha_native, :paired, %{"phone" => phone}} -> IO.puts("paired as #{phone}")
end

# Same facade as the WAHA / Meta providers
ExWaha.send_text(account, "+201001234567", "Hello!")
```

### Phone pairing code (no QR scanner)

```elixir
{:ok, "ABCD-EFGH"} =
  ExWahaNative.Session.request_pairing_code(account, "+201001234567")
# Enter the code on the WhatsApp app: Linked Devices -> Link with phone number.
```

### Polling status / latest QR

```elixir
:scan_qr = ExWahaNative.Session.status(account)
"2@..." = ExWahaNative.Session.qr(account)
```

### Logging out / stopping

```elixir
:ok = ExWahaNative.Session.logout(account)   # invalidates the WhatsApp pairing
:ok = ExWahaNative.Session.stop(account)     # local-only close, can resume
```

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  Elixir host application                             │
│                                                      │
│  ExWaha.send_text(native_account, ...)               │
│           │                                          │
│           ▼                                          │
│  ExWaha.Provider dispatch (registry, runtime)        │
│           │                                          │
│           ▼                                          │
│  ExWahaNative.Provider                               │
│           │                                          │
│           ▼                                          │
│  ExWahaNative.SessionSupervisor                      │
│  ├ Session profile_42 (GenServer)                    │
│  ├ Session profile_43                                │
│  └ ...                                               │
│           │                                          │
│           ▼                                          │
│  ExWahaNative.Bridge (Port GenServer)                │
│   length-prefixed JSON over stdio                    │
└─────────────────────┬────────────────────────────────┘
                      │ Port (stdin/stdout)
                      ▼
┌──────────────────────────────────────────────────────┐
│  priv/native/whatsmeow_bridge (Go binary)            │
│                                                      │
│  - tulir/whatsmeow client per session                │
│  - sqlstore (SQLite or Postgres)                     │
│  - event loop fans events back to Elixir             │
└─────────────────────┬────────────────────────────────┘
                      │ WhatsApp Multi-Device protocol
                      ▼
                 WhatsApp servers
```

### Process model

- **One Go process per BEAM node**, multiplexed by `session` field.
  Memory-efficient; mirrors how `whatsmeow` itself is designed.
- **One Elixir `Session` GenServer per WhatsApp account.** Owns subscriber
  list, current status, last QR.
- **One `Bridge` GenServer.** Owns the `Port`, correlates request/response
  refs, routes async events to the right `Session`.

### Crash semantics

If the Go process dies:
1. The Port closes; `Bridge` exits with `{:bridge_exit, status}`.
2. `ExWahaNative.Supervisor` (one_for_one) restarts `Bridge`.
3. The Go binary re-spawns and re-loads sessions from sqlstore.
4. In-flight requests get `{:error, :bridge_exited}`.
5. `Session` GenServers stay alive — they re-establish via subsequent
   calls.

If a single `Session` crashes, only that session is affected; the Bridge
and other Sessions continue.

## Wire protocol

Length-prefixed JSON. See `ExWahaNative.Wire` for the canonical reference.

```
[4-byte big-endian length][UTF-8 JSON body]
```

Three message kinds:

```json
// Elixir -> Go
{"type":"request", "ref":"<uuid>", "session":"profile_42",
 "op":"send_text", "args":{"to":"201001234567@s.whatsapp.net", "text":"hi"}}

// Go -> Elixir, correlated
{"type":"response", "ref":"<uuid>", "ok":true, "result":{"id":"3EB0..."}}

// Go -> Elixir, async
{"type":"event", "session":"profile_42", "kind":"message",
 "payload":{"from":"201001234567@s.whatsapp.net", "body":"hello"}}
```

## Building the Go binary

The `mix ex_waha_native.build_native` task wraps `go build`:

```bash
# Native build
mix ex_waha_native.build_native

# Cross-compile for production
mix ex_waha_native.build_native --target linux/amd64
mix ex_waha_native.build_native --target darwin/arm64
```

Output lands in `priv/native/whatsmeow_bridge`. Add this path to your
release:

```elixir
# rel/overlays/... or include in :files for the package
```

Pre-built binaries for common targets will ship via GitHub releases once
the project is past 0.1.0.

## Roadmap

| Version | Scope |
|---|---|
| **0.1.0** | Architecture: supervision tree, wire protocol, Elixir Bridge & Session GenServers, mix task, Go skeleton with `ping` op + stub handlers |
| **0.2.0** (current) | whatsmeow integration in Go: `open_session`, QR + phone-code pairing, `send_text`, `logout`, message + receipt + connection events |
| **0.3.0** | Media (`send_image`, `send_video`, `send_document`, `send_audio`); presence and typing events |
| **0.4.0** | Group operations; multi-device sync; history sync |
| **0.5.0** | Postgres sqlstore for multi-node BEAM clusters; session migration |
| **0.6.0** | Pre-built binary distribution via GitHub releases (no Go toolchain required for users) |

## License

MIT for the Elixir code. See the LICENSE file. The Go bridge depends on
[whatsmeow](https://github.com/tulir/whatsmeow) which is **MPL-2.0** —
review their license before redistributing the compiled binary.

## Disclaimer

WhatsApp's Terms of Service do not permit unofficial clients. Using
`whatsmeow` (and therefore this package) on a production WhatsApp account
carries real risk of account ban. Read
[`ex_waha`'s safety guide](https://hexdocs.pm/ex_waha/safety_and_bans.html)
before going to production. For commercial use cases consider Meta's
official Cloud API via `ExWaha.Providers.Meta`.
