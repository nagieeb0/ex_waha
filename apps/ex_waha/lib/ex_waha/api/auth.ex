defmodule ExWaha.Api.Auth do
  @moduledoc """
  Pairing endpoints — QR scan and SMS code request.

  WhatsApp authentication happens once per session. Render the QR (or
  request a numeric code) to the user, who confirms in the WhatsApp mobile
  app under *Linked Devices*.

  After a successful pairing, WAHA fires a `session.status` webhook with
  status `WORKING`. Update your `ExWaha.Session.Server` accordingly.
  """

  import ExWaha.Api.Helpers

  alias ExWaha.Providers.Waha.Account

  @doc """
  Fetch the QR code for the session.

  ## Options

    * `:format` — `:raw` (default) or `:image`
      - `:raw` returns `{:ok, %{"value" => "<base64>"}}`
      - `:image` returns the raw PNG bytes (caller decodes)

  ## Example (LiveView)

      def handle_info(:poll_qr, socket) do
        case ExWaha.Api.Auth.qr(socket.assigns.account, format: :raw) do
          {:ok, %{"value" => b64}} ->
            {:noreply, assign(socket, qr: b64)}

          {:error, _} ->
            Process.send_after(self(), :poll_qr, 2000)
            {:noreply, socket}
        end
      end
  """
  @spec qr(Account.t(), keyword()) :: {:ok, any()} | {:error, ExWaha.Error.t()}
  def qr(%Account{instance: inst, session: s}, opts \\ []) do
    format = Keyword.get(opts, :format, :raw)
    path = "/api/" <> s <> "/auth/qr?format=#{format}"
    request(inst, :get, path, nil)
  end

  @doc """
  Request a numeric pairing code (alternative to QR scanning).

  Useful when the user can't easily scan a screen — they enter the returned
  code in WhatsApp → Linked Devices → Link with phone number instead.

      ExWaha.Api.Auth.request_code(account, "+201001234567")
      #=> {:ok, %{"code" => "ABC1-DEF2"}}
  """
  @spec request_code(Account.t(), String.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def request_code(%Account{instance: inst, session: s}, phone) do
    request(inst, :post, "/api/" <> s <> "/auth/request-code", %{phoneNumber: phone})
  end

  @doc "Take a screenshot of the WhatsApp Web view (debug aid)."
  @spec screenshot(Account.t()) :: {:ok, any()} | {:error, ExWaha.Error.t()}
  def screenshot(%Account{instance: inst, session: s}) do
    request(inst, :get, "/api/screenshot?session=" <> s, nil)
  end
end
