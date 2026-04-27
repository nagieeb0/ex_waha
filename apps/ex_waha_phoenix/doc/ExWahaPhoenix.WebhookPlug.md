# `ExWahaPhoenix.WebhookPlug`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha_phoenix/webhook_plug.ex#L1)

Plug that receives webhook POSTs from WAHA or Meta, verifies the HMAC
signature, parses the payload into normalized events, and dispatches them
to the host application's handler module.

## Mounting

    forward "/webhooks/waha/:account_id",
            ExWahaPhoenix.WebhookPlug,
            handler: MyAppWeb.WahaHandler,
            account: {MyApp.Whatsapp, :account_for, []}

The `:account` option is an MFA called with `[conn]` to resolve the account
struct (so you can route by URL param to the right tenant).

## Raw body

Signature verification needs the *raw* request body. Add this to your
endpoint's parsers:

    plug Plug.Parsers,
      parsers: [:urlencoded, :json],
      json_decoder: Jason,
      body_reader: {ExWahaPhoenix.WebhookPlug, :read_body, []}

# `read_body`

Body reader to plug into `Plug.Parsers` so the raw body remains available
for HMAC verification after JSON parsing.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
