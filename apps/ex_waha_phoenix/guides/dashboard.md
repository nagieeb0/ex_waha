# Dashboard

`ExWahaPhoenix.Dashboard` is a mountable LiveView that gives you a
LiveDashboard-style view of your WAHA sessions: status, paired number, QR
scan modal, recent events, and a send-test form.

> **Status: skeleton in 0.1.0.** The mountable module compiles and renders
> a placeholder. The full UI ships in 0.2.0; the contract below is what to
> expect.

## Mounting

```elixir
scope "/admin", MyAppWeb do
  pipe_through [:browser, :require_admin]
  live "/whatsapp", ExWahaPhoenix.Dashboard, :index
end
```

The dashboard has **no built-in authentication** — that's intentional.
Always mount it under a pipeline that enforces who can see it. A leaked
dashboard exposes per-tenant message history and lets viewers send messages.

## Optional dependency

`:phoenix_live_view` is `optional: true` in the package — the module is
defined inside an `if Code.ensure_loaded?(Phoenix.LiveView)` guard, so the
package compiles cleanly in projects that don't have LiveView.

If you mount the dashboard, you must add LiveView as a direct dependency:

```elixir
{:phoenix_live_view, "~> 1.0"}
```

## Planned features

- Sessions table — live status (subscribes to `Session.Server` notifications)
- QR pairing flow — modal that polls `Api.Auth.qr/2` until `:working`
- Per-account event stream — last N webhooks for debugging
- Send-test form — validates and dispatches a real `send_text/4`
- Per-instance health check — pings each `%Instance{}` for version + uptime

## Customization

Once the full version ships, you'll be able to override:

```elixir
live "/whatsapp", ExWahaPhoenix.Dashboard, :index,
  session: %{
    "page_title" => "WhatsApp Admin",
    "accounts_for_user" => {MyApp.Whatsapp, :list_accounts_for, []}
  }
```

Stay tuned.
