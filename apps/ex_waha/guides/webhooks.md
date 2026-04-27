# Webhooks

ExWaha normalizes the wildly different webhook payload shapes from WAHA
and Meta into a single `%ExWaha.Webhooks.Event{}` struct that your
application code consumes.

## Pipeline

```
HTTP POST → verify HMAC → JSON decode → parse_event → handler.handle_event/2
            (Signature)                  (Provider)    (your module)
```

If you're on Phoenix, [`ExWahaPhoenix.WebhookPlug`](https://hexdocs.pm/ex_waha_phoenix)
runs that whole pipeline for you. For other transports, do it manually.

## Implementing a handler

```elixir
defmodule MyApp.Whatsapp.Handler do
  @behaviour ExWaha.Webhooks.Handler

  alias ExWaha.Webhooks.Event

  def handle_event(%Event{kind: :message} = e, ctx) do
    MyApp.Whatsapp.persist_inbound(e, ctx.account)
    Phoenix.PubSub.broadcast(MyApp.PubSub, "wa:#{ctx.account.session}", {:msg, e})
    :ok
  end

  def handle_event(%Event{kind: :message_ack} = e, _ctx) do
    MyApp.Whatsapp.update_delivery_state(e.raw["id"], e.ack_status)
  end

  def handle_event(%Event{kind: :session_status, raw: raw}, ctx) do
    new = String.downcase(raw["status"]) |> String.to_existing_atom()
    pid = ExWaha.Session.Registry.via(ctx.account)
    ExWaha.Session.Server.set_status(pid, new)
  end

  def handle_event(_event, _ctx), do: :ok
end
```

The handler runs synchronously inside the webhook request. **Don't do slow
work here** — push to Oban / Task.Supervisor for anything beyond a DB write
or PubSub broadcast.

## Event reference

`%ExWaha.Webhooks.Event{}` fields:

| Field | Type | Notes |
|---|---|---|
| `provider` | `:waha \| :meta` | |
| `kind` | `:message \| :message_ack \| :message_reaction \| :session_status \| :group_update \| :presence \| :unknown` | Normalized across providers |
| `session` | `String.t() \| nil` | WAHA session name; nil for Meta |
| `timestamp` | `DateTime.t() \| nil` | |
| `from` | `String.t() \| nil` | Chat id (`...@c.us`) for WAHA, E.164 for Meta |
| `to` | `String.t() \| nil` | |
| `chat_id` | `String.t() \| nil` | WAHA only |
| `body` | `String.t() \| nil` | Text body for `:message` kind |
| `media` | `map() \| nil` | Media descriptor (when present) |
| `ack_status` | `atom() \| String.t() \| nil` | `:sent \| :delivered \| :read \| :played` (or string from Meta) |
| `raw` | `map()` | Full provider payload — fall back here for fields the normalized form doesn't expose |

## HMAC signatures

Both providers sign the **raw request body**. If your stack runs `Plug.Parsers`
before signature verification, the body is gone — use the body reader from
`ExWahaPhoenix.WebhookPlug` (or capture it manually).

| Provider | Algorithm | Header | Format |
|---|---|---|---|
| WAHA | HMAC-SHA512 | `X-Webhook-Hmac` | hex digest |
| Meta | HMAC-SHA256 | `X-Hub-Signature-256` | `sha256=<hex>` |

Manual verification:

```elixir
# WAHA
ExWaha.Webhooks.Signature.verify_sha512(raw_body, header_value, account.webhook_secret)

# Meta
ExWaha.Webhooks.Signature.verify_meta_sha256(raw_body, header_value, account.app_secret)
```

Comparison is constant-time via `:crypto.hash_equals/2`.

## WAHA event names

WAHA sends one event per HTTP POST. Common `event` values:

- `message` — incoming message
- `message.ack` — sent-message status update
- `message.reaction` — emoji reaction added/removed
- `session.status` — session transitioned (e.g. `WORKING → FAILED`)
- `group.v2.join` / `group.v2.leave` / `group.v2.update`
- `presence.update`

`Event.from_waha/1` maps these to `kind`. Anything unrecognized lands as
`:unknown` with the original payload in `raw`.

## Meta event payloads

Meta posts an envelope with multiple entries → changes → values. ExWaha
flattens to a list of `%Event{}` structs. A single POST commonly contains
both inbound `messages` and outbound `statuses` for previously-sent
messages.

## Configuring webhooks

WAHA session config (passed to `ExWaha.Api.Sessions.create/2`):

```elixir
ExWaha.Api.Sessions.create(account, %{
  webhooks: [
    %{
      url: "https://api.example.com/webhooks/waha/profile_42",
      events: ["message", "message.ack", "session.status"],
      hmac: %{key: account.webhook_secret}
    }
  ]
})
```

Meta webhooks are configured in the App Dashboard, not via API.
