# ExWahaPhoenix v0.1.0 - API Reference

## Modules

- [ExWahaPhoenix](ExWahaPhoenix.md): Phoenix adapter for ex_waha.
- [ExWahaPhoenix.Dashboard](ExWahaPhoenix.Dashboard.md): Mountable LiveView dashboard for ex_waha sessions.
- [ExWahaPhoenix.WebhookPlug](ExWahaPhoenix.WebhookPlug.md): Plug that receives webhook POSTs from WAHA or Meta, verifies the HMAC
signature, parses the payload into normalized events, and dispatches them
to the host application's handler module.

