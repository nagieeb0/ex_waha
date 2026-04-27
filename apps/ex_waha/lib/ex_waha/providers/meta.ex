defmodule ExWaha.Providers.Meta do
  @moduledoc """
  Provider implementation for Meta's WhatsApp Business Cloud API.

  Reference: https://developers.facebook.com/docs/whatsapp/cloud-api

  Differences vs WAHA:

    * Auth is `Authorization: Bearer <access_token>`.
    * Outbound URL is `POST https://graph.facebook.com/<api_version>/<phone_number_id>/messages`.
    * Free-form messages only allowed inside the 24-hour customer service window.
      Outside that window you must use a pre-approved `template`.
    * Webhook signature is `X-Hub-Signature-256: sha256=<hex>` over the raw body
      using the App Secret.
  """

  @behaviour ExWaha.Provider

  alias ExWaha.{Client, Error, Recipient, Telemetry}
  alias ExWaha.Providers.Meta.Account
  alias ExWaha.Webhooks.{Event, Signature}

  @impl true
  def send_text(%Account{} = account, recipient, text, opts) do
    body = %{
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: Recipient.to_meta(recipient),
      type: "text",
      text: %{preview_url: Keyword.get(opts, :preview_url, false), body: text}
    }

    request(account, body, %{op: :send_text})
  end

  @impl true
  def send_media(%Account{} = account, recipient, media, _opts) do
    type = Map.fetch!(media, :type)

    body =
      %{
        messaging_product: "whatsapp",
        to: Recipient.to_meta(recipient),
        type: Atom.to_string(type)
      }
      |> Map.put(Atom.to_string(type), Map.delete(media, :type))

    request(account, body, %{op: :send_media})
  end

  @impl true
  def send_template(%Account{} = account, recipient, template_name, opts) do
    body = %{
      messaging_product: "whatsapp",
      to: Recipient.to_meta(recipient),
      type: "template",
      template: %{
        name: template_name,
        language: %{code: Keyword.get(opts, :language, "en_US")},
        components: Keyword.get(opts, :components, [])
      }
    }

    request(account, body, %{op: :send_template})
  end

  @impl true
  def verify_signature(%Account{app_secret: secret}, body, headers) do
    sig =
      Enum.find_value(headers, fn {k, v} ->
        if String.downcase(to_string(k)) == "x-hub-signature-256", do: v
      end)

    Signature.verify_meta_sha256(body, sig, secret)
  end

  @impl true
  def parse_event(%Account{}, payload) when is_map(payload) do
    {:ok, Event.from_meta(payload)}
  end

  defp request(account, body, meta) do
    url =
      Path.join([
        account.api_base,
        account.api_version,
        account.phone_number_id,
        "messages"
      ])

    headers = [
      {"authorization", "Bearer " <> account.access_token},
      {"content-type", "application/json"}
    ]

    Telemetry.span([:request], Map.put(meta, :provider, :meta), fn ->
      case Client.request(:post, url, headers, body, []) do
        {:ok, %{status: s, body: b}} when s in 200..299 -> {:ok, b}
        {:ok, %{status: s, body: b}} -> {:error, Error.from_status(s, b)}
        {:error, %Error{}} = err -> err
      end
    end)
  end
end
