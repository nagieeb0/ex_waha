# ExWahaPhoenix

[![Hex.pm](https://img.shields.io/hexpm/v/ex_waha_phoenix.svg)](https://hex.pm/packages/ex_waha_phoenix)
[![Documentation](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_waha_phoenix)

Phoenix adapter for [`ex_waha`](https://hex.pm/packages/ex_waha) — a mountable
webhook plug, a body reader to preserve raw bodies for HMAC verification,
and a LiveView dashboard skeleton.

## Installation

```elixir
def deps do
  [
    {:ex_waha, "~> 0.1.0"},
    {:ex_waha_phoenix, "~> 0.1.0"}
  ]
end
```

`:phoenix_live_view` is an *optional* dependency. The dashboard module only
compiles if LiveView is installed.

## Receiving webhooks

### 1. Capture the raw body in your endpoint

HMAC verification needs the byte-exact request body. Tell `Plug.Parsers` to
use `ExWahaPhoenix.WebhookPlug.read_body/2`:

```elixir
# lib/my_app_web/endpoint.ex
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library(),
  body_reader: {ExWahaPhoenix.WebhookPlug, :read_body, []}
```

### 2. Mount the plug in your router

```elixir
# lib/my_app_web/router.ex
scope "/webhooks", MyAppWeb do
  forward "/waha/:profile_id",
          ExWahaPhoenix.WebhookPlug,
          handler: MyApp.Whatsapp.Handler,
          account: {MyApp.Whatsapp, :account_for_conn, []}
end
```

`:account` is an MFA called with `[conn]` (or a 1-arity function). It returns
the `%ExWaha.Providers.Waha.Account{}` (or Meta account) for this request,
so different URL params route to different tenants.

```elixir
defmodule MyApp.Whatsapp do
  def account_for_conn(%Plug.Conn{} = conn) do
    profile_id = conn.path_params["profile_id"]
    account_for(profile_id)
  end
end
```

### 3. Implement the handler

```elixir
defmodule MyApp.Whatsapp.Handler do
  @behaviour ExWaha.Webhooks.Handler

  alias ExWaha.Webhooks.Event

  def handle_event(%Event{kind: :message} = event, ctx) do
    MyApp.Whatsapp.persist_inbound(event, ctx.account)
    Phoenix.PubSub.broadcast(MyApp.PubSub, topic(ctx), {:inbound, event})
    :ok
  end

  def handle_event(%Event{kind: :session_status, raw: raw}, ctx) do
    new = raw["status"] |> String.downcase() |> String.to_existing_atom()
    ExWaha.Session.Server.set_status(
      ExWaha.Session.Registry.via(ctx.account),
      new
    )
  end

  def handle_event(_event, _ctx), do: :ok

  defp topic(%{account: account}), do: "whatsapp:#{account.session}"
end
```

The plug verifies the HMAC, parses the JSON, and dispatches each normalized
event to your handler. On signature failure it returns `401`; on bad JSON,
`400`; otherwise `200 ok`.

## Configuring WAHA's webhook

In your WAHA session config:

```json
{
  "webhooks": [
    {
      "url": "https://api.example.com/webhooks/waha/42",
      "events": ["message", "message.ack", "session.status"],
      "hmac": { "key": "the-same-secret-you-passed-to-Account.new" }
    }
  ]
}
```

## Configuring Meta's webhook

In Meta App Dashboard → WhatsApp → Configuration:

- **Callback URL**: `https://api.example.com/webhooks/waha/<phone_number_id>`
- **Verify token**: anything; your handler must respond to the GET
  challenge separately (see Meta docs).
- **App Secret**: pass to `ExWaha.Providers.Meta.Account.new/1` as `:app_secret`.

## Dashboard

A mountable LiveView is available as a skeleton in
`ExWahaPhoenix.Dashboard`. Mount it under your auth pipeline:

```elixir
scope "/admin", MyAppWeb do
  pipe_through [:browser, :require_admin]
  live "/whatsapp", ExWahaPhoenix.Dashboard, :index
end
```

The full UI (sessions list, QR scan, status, send-test) is rolling out — see
[Dashboard guide](guides/dashboard.md).

## Documentation

- [Webhook reference](guides/webhooks.md)
- [Dashboard](guides/dashboard.md)

## License

MIT. See the LICENSE file included in the package.
