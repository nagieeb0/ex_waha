# ExWaha

[![Hex.pm](https://img.shields.io/hexpm/v/ex_waha.svg)](https://hex.pm/packages/ex_waha)
[![Documentation](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_waha)

Provider-agnostic WhatsApp client for Elixir. Talk to a self-hosted [WAHA](https://waha.devlike.pro)
server **or** Meta's official WhatsApp Business Cloud API through the same
function calls. Multi-tenant by construction. Ban-aware by default.

> **Heads up:** Sending WhatsApp messages — especially via WAHA, which uses the
> WhatsApp Web protocol — carries real risk of account bans. Read
> [Safety and bans](guides/safety_and_bans.md) before going to production.

## Installation

Add `:ex_waha` to your `mix.exs`:

```elixir
def deps do
  [
    {:ex_waha, "~> 0.1.0"}
  ]
end
```

If you'll receive webhooks via Phoenix, also add
[`:ex_waha_phoenix`](https://hex.pm/packages/ex_waha_phoenix). If you use Ash,
add [`:ash_waha`](https://hex.pm/packages/ash_waha).

If you don't want to run a WAHA Docker container, add
[`:ex_waha_native`](https://hex.pm/packages/ex_waha_native) and call the same
`ExWaha.send_text/3` against an `ExWahaNative.Account` — it talks the
WhatsApp Multi-Device protocol directly via a supervised Go (`whatsmeow`)
sidecar.

## Quick start

```elixir
# 1. Build a per-tenant account struct
account =
  ExWaha.Providers.Waha.Account.new(
    ExWaha.Instance.new(
      base_url: "http://waha.internal:3000",
      api_key: System.fetch_env!("WAHA_API_KEY")
    ),
    "profile_42",                       # session name (your tenant id, derived)
    webhook_secret: System.fetch_env!("WAHA_WEBHOOK_SECRET")
  )

# 2. Bring it under the safety supervisor (rate limit + warmup + jitter)
{:ok, _pid} = ExWaha.Session.Supervisor.ensure_started(account)

# 3. After WAHA reports the WhatsApp pairing succeeded, mark it sendable
ExWaha.Session.Server.set_status(
  ExWaha.Session.Registry.via(account),
  :working
)

# 4. Send messages through the safe gate
{:ok, _resp} = ExWaha.send_text(account, "+20 100 123 4567", "Hi!")
```

## Architecture

```
                       ExWaha (facade)
                            │
                       SafeSend (gate)
                       │           │
        Session.Server (per acct)  └──── (no server: bypass)
        ├ token bucket
        ├ warmup curve
        ├ jitter
        └ status state
                            │
                    Provider (behaviour)
                  ┌─────────┴──────────┐
        Providers.Waha           Providers.Meta
              │                          │
        Api.* modules              Cloud API calls
              │                          │
                  Client (behaviour)
                  ├ Client.Req (default)
                  └ ClientMock  (test)
```

The OTP layer is **opt-in**. Calls without a registered `Session.Server`
fall through to the raw HTTP client, useful for tests and one-off scripts.

## Two providers, one API

```elixir
# Self-hosted WAHA
waha = ExWaha.Providers.Waha.Account.new(instance, "profile_42")
ExWaha.send_text(waha, "+201001234567", "via WAHA")

# Meta Cloud API
meta =
  ExWaha.Providers.Meta.Account.new(
    phone_number_id: System.fetch_env!("META_PHONE_NUMBER_ID"),
    access_token:    System.fetch_env!("META_ACCESS_TOKEN"),
    app_secret:      System.fetch_env!("META_APP_SECRET")
  )

ExWaha.send_text(meta, "+201001234567", "via Meta")
ExWaha.send_template(meta, "+201001234567", "hello_world", language: "en_US")
```

## Multi-tenancy

ExWaha owns no persistence. Your application maps `profile_id` → account in
its own database. The recommended convention is a deterministic session name:

```elixir
defmodule MyApp.Whatsapp do
  alias ExWaha.{Instance, Providers.Waha.Account}

  def account_for(profile_id) do
    Account.new(
      Instance.new(base_url: waha_base_url(), api_key: waha_api_key()),
      "profile_#{profile_id}",
      webhook_secret: waha_webhook_secret()
    )
  end
end
```

For per-tenant WAHA instances (different servers per customer), look up the
URL/key from your `instances` table inside `account_for/1`.

See [Multi-tenancy guide](guides/multi_tenancy.md).

## Receiving webhooks

If you're on Phoenix, use [`ExWahaPhoenix.WebhookPlug`](https://hexdocs.pm/ex_waha_phoenix).
For other transports, call `ExWaha.Webhooks.Handler.dispatch/3` from your
controller.

```elixir
defmodule MyApp.Whatsapp.Handler do
  @behaviour ExWaha.Webhooks.Handler

  def handle_event(%ExWaha.Webhooks.Event{kind: :message} = event, ctx) do
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "whatsapp:#{ctx.account.session}",
      {:waha_message, event}
    )
    :ok
  end

  def handle_event(_, _ctx), do: :ok
end
```

See [Webhooks guide](guides/webhooks.md).

## Telemetry

Every outbound call is wrapped in a `:telemetry.span/3`. Subscribe with the
standard machinery — no per-app integration needed.

```elixir
:telemetry.attach_many(
  "ex-waha-logger",
  [
    [:ex_waha, :request, :stop],
    [:ex_waha, :rate_limit, :throttled],
    [:ex_waha, :session, :status_changed]
  ],
  &MyApp.Telemetry.handle_event/4,
  nil
)
```

See [Telemetry events](guides/telemetry.md) for the full list.

## Documentation

- [Getting started](guides/getting_started.md)
- [Multi-tenancy](guides/multi_tenancy.md)
- [Safety and bans](guides/safety_and_bans.md)
- [Webhooks](guides/webhooks.md)
- [Providers (WAHA & Meta)](guides/providers.md)
- [Telemetry events](guides/telemetry.md)

## License

MIT. See the LICENSE file included in the package.
