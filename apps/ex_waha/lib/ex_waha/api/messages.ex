defmodule ExWaha.Api.Messages do
  @moduledoc """
  Message-sending endpoints for WAHA.

  Note: passing through `ExWaha.SafeSend` is strongly recommended over calling
  these directly — the safe layer enforces rate limits, warmup, and jitter.
  """

  import ExWaha.Api.Helpers

  alias ExWaha.{Recipient, Providers.Waha.Account}

  @spec send_text(Account.t(), Recipient.t() | String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def send_text(%Account{instance: inst, session: s}, recipient, text, opts \\ []) do
    body =
      %{
        chatId: chat_id(recipient),
        text: text,
        session: s
      }
      |> maybe_put(:reply_to, opts[:reply_to])
      |> maybe_put(:linkPreview, opts[:link_preview])

    request(inst, :post, "/api/sendText", body, %{op: :send_text})
  end

  @spec send_media(Account.t(), Recipient.t() | String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def send_media(%Account{instance: inst, session: s}, recipient, media, _opts \\ []) do
    type = Map.fetch!(media, :type)

    path =
      case type do
        :image -> "/api/sendImage"
        :video -> "/api/sendVideo"
        :audio -> "/api/sendVoice"
        :document -> "/api/sendFile"
      end

    body =
      media
      |> Map.delete(:type)
      |> Map.merge(%{chatId: chat_id(recipient), session: s})

    request(inst, :post, path, body, %{op: :send_media, media_type: type})
  end

  @spec send_location(Account.t(), Recipient.t() | String.t(), map()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def send_location(%Account{instance: inst, session: s}, recipient, %{lat: lat, lng: lng} = loc) do
    body = %{
      chatId: chat_id(recipient),
      latitude: lat,
      longitude: lng,
      title: Map.get(loc, :title),
      session: s
    }

    request(inst, :post, "/api/sendLocation", body, %{op: :send_location})
  end

  @spec send_seen(Account.t(), Recipient.t() | String.t()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def send_seen(%Account{instance: inst, session: s}, recipient) do
    request(inst, :post, "/api/sendSeen", %{chatId: chat_id(recipient), session: s})
  end

  defp chat_id(%Recipient{} = r), do: Recipient.to_waha(r)
  defp chat_id(s) when is_binary(s), do: Recipient.to_waha(Recipient.new(s))

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
