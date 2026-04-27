# ExWaha — Umbrella

Provider-agnostic WhatsApp client for Elixir, with first-class multi-tenancy
and bake-in protection against WhatsApp's anti-spam systems.

This is the umbrella project. Four packages live under `apps/`:

| Package | Hex (planned) | Purpose |
|---|---|---|
| [`ex_waha`](apps/ex_waha) | `:ex_waha` | Pure core: HTTP client, providers (WAHA + Meta Cloud API), OTP safety layer, webhooks. No Phoenix, no Ash. |
| [`ex_waha_phoenix`](apps/ex_waha_phoenix) | `:ex_waha_phoenix` | Phoenix adapter: mountable webhook plug + LiveView dashboard. |
| [`ash_waha`](apps/ash_waha) | `:ash_waha` | Ash extension: declarative `whatsapp` resource DSL + Ash changes. |
| [`ex_waha_native`](apps/ex_waha_native) | `:ex_waha_native` | Native provider via Go (`whatsmeow`) sidecar — no WAHA Docker container needed. |

## Why four packages?

Most projects only need `ex_waha`. Add the adapter packages only when you want
their integration surface. Keeping the core framework-free means it stays
useful on plain OTP, Plug-only apps, and future frameworks.

The `ex_waha_native` package is a self-contained alternative to running a WAHA
container: it ships a tiny Go binary (built from
[`whatsmeow`](https://github.com/tulir/whatsmeow)) supervised by a BEAM Port,
so you get the same WhatsApp Multi-Device protocol without Docker.

## Quick taste

```elixir
# Pick your provider
account =
  ExWaha.Providers.Waha.Account.new(
    ExWaha.Instance.new(base_url: "http://waha:3000", api_key: System.fetch_env!("WAHA_API_KEY")),
    "profile_42"
  )

# Bring it under supervision (enables rate limit + warmup + jitter)
{:ok, _pid} = ExWaha.Session.Supervisor.ensure_started(account)
ExWaha.Session.Server.set_status(account |> ExWaha.Session.Registry.via(), :working)

# Send
{:ok, _} = ExWaha.send_text(account, "+20 100 123 4567", "Hello!")
```

The full guided walkthrough lives in [`apps/ex_waha/README.md`](apps/ex_waha/README.md).

## Examples

Runnable scripts in [`examples/`](examples) cover the four common shapes:

| Script | What it does |
| --- | --- |
| [`01_send_via_waha.exs`](examples/01_send_via_waha.exs) | Sends through a self-hosted WAHA server. |
| [`02_send_via_meta.exs`](examples/02_send_via_meta.exs) | Sends through Meta WhatsApp Business Cloud API (free-form + template). |
| [`03_send_via_native.exs`](examples/03_send_via_native.exs) | Pairs a new device through the Go bridge and sends without any external service. |
| [`04_phoenix_webhook.exs`](examples/04_phoenix_webhook.exs) | Wires `ExWahaPhoenix.WebhookPlug` into a Phoenix endpoint and shows a handler. |

See [`examples/README.md`](examples/README.md) for environment variables and pre-reqs.

## Development

```bash
mix deps.get
mix compile
mix test
mix format --check-formatted

# build the Go bridge for ex_waha_native (only required to use the native provider)
mix ex_waha_native.build_native
```

## License

MIT — see [LICENSE](LICENSE).
