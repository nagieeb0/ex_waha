# Phoenix webhook integration snippet.
#
# This file is *not* meant to be `mix run`. It is a copy-paste-ready
# reference showing where the WAHA / Meta webhook plug fits into a
# typical Phoenix endpoint, and what a handler module looks like.
#
# Copy the four code blocks below into the matching files of your app.

# ---------------------------------------------------------------------
# 1.  lib/my_app_web/endpoint.ex — wire up the raw-body reader BEFORE
#     parsers, so HMAC verification can see the unparsed body.
# ---------------------------------------------------------------------

defmodule MyAppWeb.Endpoint.Example do
  @moduledoc false
  # use Phoenix.Endpoint, otp_app: :my_app

  # plug Plug.Parsers,
  #   parsers: [:urlencoded, :json],
  #   pass: ["*/*"],
  #   json_decoder: Jason,
  #   body_reader: {ExWahaPhoenix.WebhookPlug, :read_body, []}
end

# ---------------------------------------------------------------------
# 2.  lib/my_app_web/router.ex — forward the inbound webhook URL to the
#     plug. The :account option resolves a tenant per request.
# ---------------------------------------------------------------------

defmodule MyAppWeb.Router.Example do
  @moduledoc false
  # use Phoenix.Router

  # pipeline :webhook do
  #   plug :accepts, ["json"]
  # end

  # scope "/", MyAppWeb do
  #   pipe_through :webhook
  #
  #   forward "/webhooks/waha/:profile_id",
  #           ExWahaPhoenix.WebhookPlug,
  #           handler: MyAppWeb.WhatsappHandler,
  #           account: {MyApp.Whatsapp, :account_for_conn, []}
  # end
end

# ---------------------------------------------------------------------
# 3.  lib/my_app/whatsapp.ex — resolve the account based on the URL
#     param. The Phoenix conn arrives with `path_params["profile_id"]`.
# ---------------------------------------------------------------------

defmodule MyApp.Whatsapp.Example do
  @moduledoc false

  def account_for_conn(%Plug.Conn{path_params: %{"profile_id" => profile_id}}) do
    # In a real app, look up the row from your DB. Here we hardcode.
    instance = ExWaha.Instance.new(base_url: "http://localhost:3000", api_key: "key")
    ExWaha.Providers.Waha.Account.new(instance, "profile_" <> profile_id, webhook_secret: "shh")
  end
end

# ---------------------------------------------------------------------
# 4.  lib/my_app_web/whatsapp_handler.ex — process normalized events.
#     The handler receives the same shape regardless of whether the
#     payload originated from WAHA or Meta.
# ---------------------------------------------------------------------

defmodule MyAppWeb.WhatsappHandler.Example do
  @behaviour ExWaha.Webhooks.Handler

  require Logger

  @impl true
  def handle_event(%{type: :message, from: from, body: body} = _event, %{account: account}) do
    Logger.info("inbound from #{from} on #{account.session}: #{inspect(body)}")

    # Echo bot — reply right back via the safety gate.
    ExWaha.send_text(account, from, "you said: #{inspect(body)}")
  end

  def handle_event(%{type: :message_ack, status: status, message_id: id}, _ctx) do
    Logger.info("ack #{status} for #{id}")
  end

  def handle_event(_event, _ctx), do: :ok
end
