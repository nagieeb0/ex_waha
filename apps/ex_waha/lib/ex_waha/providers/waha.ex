defmodule ExWaha.Providers.Waha do
  @moduledoc """
  Provider implementation for self-hosted WAHA (https://waha.devlike.pro).

  All requests go through the configurable `ExWaha.Client`. The session
  parameter scopes the call to a single WhatsApp account on the WAHA server.
  """

  @behaviour ExWaha.Provider

  alias ExWaha.Api.Messages
  alias ExWaha.Providers.Waha.Account
  alias ExWaha.Webhooks.{Event, Signature}

  @impl true
  def send_text(%Account{} = account, recipient, text, opts) do
    Messages.send_text(account, recipient, text, opts)
  end

  @impl true
  def send_media(%Account{} = account, recipient, media, opts) do
    Messages.send_media(account, recipient, media, opts)
  end

  @impl true
  def send_template(_account, _recipient, _template, _opts) do
    {:error,
     ExWaha.Error.exception(
       reason: :forbidden,
       message: "WAHA does not support Meta templates — use Providers.Meta for templates."
     )}
  end

  @impl true
  def verify_signature(%Account{webhook_secret: nil}, _body, _headers), do: true

  def verify_signature(%Account{webhook_secret: secret}, body, headers) do
    sig = header(headers, "x-webhook-hmac") || header(headers, "x-webhook-signature")
    Signature.verify_sha512(body, sig, secret)
  end

  @impl true
  def parse_event(%Account{}, payload) when is_map(payload) do
    {:ok, [Event.from_waha(payload)]}
  end

  defp header(headers, name) do
    name = String.downcase(name)

    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(to_string(k)) == name, do: v
    end)
  end
end
