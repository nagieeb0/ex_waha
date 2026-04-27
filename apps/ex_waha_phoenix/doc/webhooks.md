# Webhook reference

`ExWahaPhoenix.WebhookPlug` is a `Plug` (not a Phoenix controller) that
runs the full receive pipeline:

```
read raw body → verify HMAC → JSON decode → parse_event → dispatch handler
```

It returns:

- `200 ok` on success
- `401 invalid signature` on HMAC mismatch
- `400 invalid json` / `400 bad request` on malformed payloads

## Mounting

```elixir
forward "/webhooks/waha/:profile_id",
        ExWahaPhoenix.WebhookPlug,
        handler: MyApp.Whatsapp.Handler,
        account: {MyApp.Whatsapp, :account_for_conn, []},
        context: %{source: :phoenix}
```

### Options

| Option | Required | Description |
|---|---|---|
| `:handler` | yes | Module implementing `ExWaha.Webhooks.Handler` |
| `:account` | yes | MFA, 1-arity function `(conn -> account)`, or static account struct |
| `:context` | no | Extra map merged into the handler context (defaults to `%{}`) |

The handler receives `%{account: account, conn: conn}` merged with your
`:context`.

## The body reader

`Plug.Parsers` consumes the request body — by the time your plug runs,
`Plug.Conn.read_body/2` returns `""`. Without raw bytes, HMAC verification
will fail.

Add the body reader to your endpoint **before** the parsers run:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library(),
  body_reader: {ExWahaPhoenix.WebhookPlug, :read_body, []}
```

`read_body/2` is a thin wrapper that caches the bytes in `conn.private`
under `:ex_waha_raw_body`, so the plug can re-read them later.

## Per-account isolation

The `:account` resolver is the join point between the URL and the tenant.
A clean implementation keeps it explicit:

```elixir
defmodule MyApp.Whatsapp do
  @spec account_for_conn(Plug.Conn.t()) :: ExWaha.Providers.Waha.Account.t()
  def account_for_conn(%Plug.Conn{path_params: %{"profile_id" => id}}) do
    account_for!(id)
  end
end
```

Never trust webhook payload fields to identify the tenant — those are
attacker-controlled. Always derive from the URL (which is signed).

## Async handler work

Handlers run synchronously inside the request. Long work belongs in Oban:

```elixir
def handle_event(%Event{kind: :message} = event, ctx) do
  %{event: Map.from_struct(event), profile_id: profile_id(ctx)}
  |> MyApp.Whatsapp.Workers.IngestInbound.new()
  |> Oban.insert()

  :ok
end
```

This keeps the WebhookPlug response under 100ms and gives you retries +
backoff for free.

## Configuring WAHA to point here

```bash
docker run -d \
  -e WHATSAPP_HOOK_URL=https://api.example.com/webhooks/waha/profile_42 \
  -e WHATSAPP_HOOK_HMAC_KEY=$WAHA_WEBHOOK_SECRET \
  devlikeapro/waha
```

Or programmatically in `Sessions.create/2`:

```elixir
ExWaha.Api.Sessions.create(account, %{
  webhooks: [
    %{
      url: "https://api.example.com/webhooks/waha/#{profile_id}",
      events: ["message", "message.ack", "session.status"],
      hmac: %{key: account.webhook_secret}
    }
  ]
})
```
