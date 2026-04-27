# Examples

End-to-end usage of the `ex_waha` umbrella from the perspective of a host
application. Each example is a standalone `.exs` script you can run with
`mix run examples/<file>.exs` from the umbrella root, after pulling deps
(`mix deps.get`).

| File | Provider | Demonstrates |
| ---- | -------- | ------------ |
| [`01_send_via_waha.exs`](01_send_via_waha.exs) | `ExWaha.Providers.Waha` | Send a text/image to WhatsApp via a self-hosted WAHA HTTP server. |
| [`02_send_via_meta.exs`](02_send_via_meta.exs) | `ExWaha.Providers.Meta` | Send a text + an approved template via Meta's WhatsApp Business Cloud API. |
| [`03_send_via_native.exs`](03_send_via_native.exs) | `ExWahaNative.Provider` | Spawn a native session via the Go bridge (no WAHA server needed) and send a message after pairing. |
| [`04_phoenix_webhook.exs`](04_phoenix_webhook.exs) | Either | Verify and route inbound WhatsApp webhooks from Phoenix using `ExWahaPhoenix.Webhook`. |

> **Pairing** — the native bridge example is interactive: it prints a QR
> string the first time it runs, and you scan it with WhatsApp on your
> phone (Linked Devices). After a successful pair, the sqlite store
> persists the session so subsequent runs auto-resume.

## Environment variables

Most examples read credentials from the environment so the scripts stay
committable. Set the relevant ones before running:

```bash
# WAHA (self-hosted)
export WAHA_BASE_URL="http://localhost:3000"
export WAHA_API_KEY="..."
export WAHA_RECIPIENT="+201001234567"

# Meta Cloud API
export META_PHONE_NUMBER_ID="..."
export META_ACCESS_TOKEN="..."
export META_RECIPIENT="+201001234567"

# Native bridge (no remote credentials — pair with QR)
export NATIVE_RECIPIENT="+201001234567"
```
