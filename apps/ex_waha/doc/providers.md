# Providers

`:ex_waha` ships two providers behind one API:

| | WAHA | Meta Cloud API |
|---|---|---|
| Hosted by | You (Docker) | Meta |
| Underlying transport | WhatsApp Web reverse-engineered | Official Meta Graph API |
| Cost | Server costs only | Per-conversation pricing |
| Onboarding | Scan QR with any WhatsApp number | Approved business + WhatsApp Business Account (WABA) |
| Free-form messaging | Always | Inside 24-hour customer service window only |
| Templates | Not really | Required outside the 24h window |
| Ban risk | **High** if abused | Low (they enforce instead) |
| Webhook signature | HMAC-SHA512 | HMAC-SHA256 (`X-Hub-Signature-256`) |

Pick WAHA for prototypes, low-volume internal use, or markets where
Business API onboarding is impractical. Pick Meta for production at scale.

## Account structs

Both implement `ExWaha.Provider`. The facade dispatches by inspecting the
struct's module:

```elixir
# WAHA
account = ExWaha.Providers.Waha.Account.new(
  ExWaha.Instance.new(base_url: "...", api_key: "..."),
  "profile_42",
  webhook_secret: "shhh"
)

# Meta
account = ExWaha.Providers.Meta.Account.new(
  phone_number_id: "123",
  access_token:    "EAAB...",
  app_secret:      "app_secret",
  business_account_id: "456",     # optional
  api_version:     "v22.0"        # default
)
```

Same call sites:

```elixir
ExWaha.send_text(account, recipient, "hi")
ExWaha.send_media(account, recipient, %{type: :image, file: %{url: "..."}})
ExWaha.send_template(account, recipient, "hello_world", language: "en_US")
```

## Send-text behavior

| | WAHA | Meta |
|---|---|---|
| Endpoint | `POST /api/sendText` | `POST /<phone_number_id>/messages` |
| Body | `{chatId, text, session}` | `{messaging_product: "whatsapp", to, type: "text", text: %{body}}` |
| Recipient format | `<digits>@c.us` | E.164 digits (no `+`) |
| 24h window | N/A | Free-form only inside the window |

## Templates (Meta only)

Outside the 24-hour customer service window, Meta requires a pre-approved
template. WAHA returns `{:error, %Error{reason: :forbidden}}` if you call
`send_template/4` against it.

```elixir
ExWaha.send_template(meta_account, recipient, "order_shipped",
  language: "en_US",
  components: [
    %{
      type: "body",
      parameters: [
        %{type: "text", text: "Mohammed"},
        %{type: "text", text: "TRACK-12345"}
      ]
    }
  ]
)
```

## Implementing a custom provider

`ExWaha.Provider` is the contract. To wrap a third backend (e.g. Twilio
WhatsApp), implement:

```elixir
defmodule MyApp.Providers.Twilio do
  @behaviour ExWaha.Provider

  defmodule Account do
    defstruct [:account_sid, :auth_token, :from]
  end

  @impl true
  def send_text(account, recipient, text, _opts), do: # ...
  @impl true
  def send_media(account, recipient, media, _opts), do: # ...
  @impl true
  def send_template(_account, _recipient, _template, _opts), do:
    {:error, ExWaha.Error.exception(reason: :forbidden, message: "no templates")}
  @impl true
  def verify_signature(account, body, headers), do: # ...
  @impl true
  def parse_event(account, payload), do: # ...
end
```

Then register it in `ExWaha.Provider.provider_for!/1` (or fork the dispatch
to a config-based lookup).

## Switching providers per tenant

Because the account *is* the dispatch key, you can run different tenants on
different providers. A premium tenant on Meta, a low-volume tenant on WAHA,
all in the same Phoenix app:

```elixir
def account_for!(profile_id) do
  case profile_tier(profile_id) do
    :premium -> meta_account_for!(profile_id)
    :basic   -> waha_account_for!(profile_id)
  end
end
```

The rest of your code doesn't care.
