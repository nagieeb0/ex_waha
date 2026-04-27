# `ExWaha.Providers.Meta`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/providers/meta.ex#L1)

Provider implementation for Meta's WhatsApp Business Cloud API.

Reference: https://developers.facebook.com/docs/whatsapp/cloud-api

Differences vs WAHA:

  * Auth is `Authorization: Bearer <access_token>`.
  * Outbound URL is `POST https://graph.facebook.com/<api_version>/<phone_number_id>/messages`.
  * Free-form messages only allowed inside the 24-hour customer service window.
    Outside that window you must use a pre-approved `template`.
  * Webhook signature is `X-Hub-Signature-256: sha256=<hex>` over the raw body
    using the App Secret.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
