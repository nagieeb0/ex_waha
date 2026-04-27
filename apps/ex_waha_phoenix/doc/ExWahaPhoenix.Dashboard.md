# `ExWahaPhoenix.Dashboard`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha_phoenix/dashboard.ex#L1)

Mountable LiveView dashboard for ex_waha sessions.

Designed to be mounted under the host application's authenticated pipeline:

    scope "/admin", MyAppWeb do
      pipe_through [:browser, :require_admin]
      live "/whatsapp", ExWahaPhoenix.Dashboard, :index
    end

Features (planned):

  * sessions table with live status (subscribes to `ExWaha.Session.Server`)
  * QR scan modal (LiveComponent that polls `ExWaha.Api.Auth.qr/2`)
  * recent webhook events stream
  * send-test-message form
  * per-instance health check

## Status

Skeleton only — full implementation follows once the API surface is
stabilized. Depends on optional `:phoenix_live_view` dep being installed
in the host umbrella.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
