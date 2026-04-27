defmodule ExWahaPhoenix.Dashboard do
  @moduledoc """
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
  """

  if Code.ensure_loaded?(Phoenix.LiveView) do
    use Phoenix.LiveView

    @impl true
    def mount(_params, _session, socket) do
      {:ok, assign(socket, sessions: [], page_title: "WhatsApp Sessions")}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="ex-waha-dashboard">
        <h1>WhatsApp Sessions</h1>
        <p>Dashboard skeleton — real UI pending.</p>
      </div>
      """
    end
  end
end
