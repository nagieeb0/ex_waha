# Getting started

This guide walks through setting up `:ex_waha` end to end with a self-hosted
WAHA server and sending the first message.

If you only want the official Meta Cloud API, skip to the
[Providers guide](providers.md) — the WAHA-specific setup steps don't apply.

## 1. Run a WAHA server

WAHA ships as a Docker image. The simplest dev setup:

```bash
docker run -it --rm \
  -p 3000:3000 \
  -e WAHA_API_KEY=dev_key \
  -e WHATSAPP_HOOK_URL=http://host.docker.internal:4000/webhooks/waha/local \
  -e WHATSAPP_HOOK_HMAC_KEY=dev_secret \
  devlikeapro/waha
```

Open `http://localhost:3000/dashboard` to confirm it's running.

## 2. Add the dependency

```elixir
# mix.exs
def deps do
  [
    {:ex_waha, "~> 0.1.0"}
  ]
end
```

`:ex_waha` starts its own application — `Application.start/2` boots a
`Registry` and the per-account `DynamicSupervisor`. You don't need to add
anything to your supervision tree.

## 3. Build an account

A `%ExWaha.Providers.Waha.Account{}` packages the server connection details
(`%ExWaha.Instance{}`) plus the per-tenant session name:

```elixir
instance =
  ExWaha.Instance.new(
    base_url: "http://localhost:3000",
    api_key: "dev_key"
  )

account =
  ExWaha.Providers.Waha.Account.new(
    instance,
    "profile_42",
    webhook_secret: "dev_secret"
  )
```

The session name is your tenancy primitive — pick a deterministic scheme
like `"profile_<id>"` so you never need a DB lookup to derive it.

## 4. Pair the WhatsApp account

WAHA needs to log in to WhatsApp once via QR code:

```elixir
# Create the session in WAHA (idempotent — safe to call repeatedly)
{:ok, _} = ExWaha.Api.Sessions.create(account)

# Poll for QR — returns a base64 PNG (or :image format for raw bytes)
{:ok, %{"value" => qr_b64}} = ExWaha.Api.Auth.qr(account, format: :raw)
```

Render the `qr_b64` value to the user (LiveView or any HTML), and have them
scan it with WhatsApp → Linked Devices.

When pairing succeeds, WAHA fires a `session.status` webhook with status
`WORKING`.

## 5. Bring the account under safety supervision

The OTP layer enforces rate limits, warmup ramping, and randomized jitter —
all critical for not getting banned.

```elixir
{:ok, _pid} = ExWaha.Session.Supervisor.ensure_started(account)

# After WAHA reports paired/working:
ExWaha.Session.Server.set_status(
  ExWaha.Session.Registry.via(account),
  :working
)
```

`ensure_started/1` is idempotent — safe to call from a controller before
each send if you don't want to wire it into a startup hook.

## 6. Send

```elixir
{:ok, _resp} = ExWaha.send_text(account, "+20 100 123 4567", "Hello!")
```

The recipient can be:
- a phone string (any format — `Recipient.new/1` strips non-digits)
- a `%ExWaha.Recipient{}` struct (use `Recipient.group/1` for groups)

## 7. Receive webhooks

If you're on Phoenix, see the [`:ex_waha_phoenix`](https://hexdocs.pm/ex_waha_phoenix)
docs.

For raw Plug/Bandit, the pattern is:

```elixir
def handle_webhook(conn, _params) do
  {:ok, body, conn} = Plug.Conn.read_body(conn)
  account = lookup_account(conn.path_params["session"])

  with true <- ExWaha.Providers.Waha.verify_signature(account, body, conn.req_headers),
       {:ok, payload} <- Jason.decode(body),
       {:ok, events} <- ExWaha.Providers.Waha.parse_event(account, payload) do
    ExWaha.Webhooks.Handler.dispatch(MyApp.Handler, events, %{account: account})
    Plug.Conn.send_resp(conn, 200, "ok")
  else
    false -> Plug.Conn.send_resp(conn, 401, "")
    _ -> Plug.Conn.send_resp(conn, 400, "")
  end
end
```

## What's next

- [Multi-tenancy guide](multi_tenancy.md) — modeling `profile_id` ↔
  `instance_id` ↔ session.
- [Safety and bans](safety_and_bans.md) — what the OTP layer protects you
  from and what it can't.
- [Webhooks](webhooks.md) — event shapes for both providers.
- [Telemetry](telemetry.md) — every event ExWaha emits.
