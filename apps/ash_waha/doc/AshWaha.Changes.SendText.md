# `AshWaha.Changes.SendText`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ash_waha/changes/send_text.ex#L1)

Ash change that sends a WhatsApp text message as part of an action.

## Options

  * `:text` — literal string to send.
  * `:text_arg` — name of an action argument whose value is the text.
  * `:recipient_attr` — name of the resource attribute holding the phone
    number. Defaults to `:phone_number`.
  * `:account` — overrides the resource-level `whatsapp.account` config.

Usage:

    update :send_welcome do
      argument :greeting, :string, default: "Welcome!"
      change AshWaha.Changes.SendText, text_arg: :greeting
    end

---

*Consult [api-reference.md](api-reference.md) for complete listing*
