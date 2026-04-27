defmodule ExWahaNative.Provider do
  @moduledoc """
  `ExWaha.Provider` implementation that routes through the Go bridge.

  Registered with `ExWaha.Provider.register/2` at application start so that
  `ExWaha.send_text(native_account, ...)` dispatches here transparently.
  """

  @behaviour ExWaha.Provider

  alias ExWaha.{Error, Recipient}
  alias ExWahaNative.{Account, Bridge}

  @impl true
  def send_text(%Account{} = account, recipient, text, _opts) do
    args = %{
      to: to_jid(recipient),
      text: text
    }

    call(account, "send_text", args)
  end

  @impl true
  def send_media(%Account{} = account, recipient, media, _opts) do
    args = %{
      to: to_jid(recipient),
      type: Atom.to_string(Map.fetch!(media, :type)),
      media: Map.delete(media, :type)
    }

    call(account, "send_media", args)
  end

  @impl true
  def send_template(_account, _recipient, _template, _opts) do
    {:error,
     Error.exception(
       reason: :forbidden,
       message: "Templates are a Meta Cloud API concept; use Providers.Meta."
     )}
  end

  @impl true
  def verify_signature(_account, _body, _headers), do: true

  @impl true
  def parse_event(_account, _payload), do: {:ok, []}

  defp call(%Account{bridge: bridge, session: session}, op, args) do
    case Bridge.call(bridge, session, op, args) do
      {:ok, result} ->
        {:ok, result}

      {:error, {code, message}} ->
        {:error, Error.exception(reason: bridge_reason(code), message: message)}

      {:error, reason} ->
        {:error, Error.exception(reason: :unknown, message: inspect(reason))}
    end
  end

  defp to_jid(%Recipient{} = r), do: jid_from_phone(Recipient.to_meta(r))

  defp to_jid(phone) when is_binary(phone) do
    phone |> Recipient.new() |> Recipient.to_meta() |> jid_from_phone()
  end

  # WhatsApp's native protocol uses `<digits>@s.whatsapp.net` for users,
  # `<group_id>@g.us` for groups.
  defp jid_from_phone(digits), do: digits <> "@s.whatsapp.net"

  defp bridge_reason("rate_limited"), do: :rate_limited
  defp bridge_reason("not_started"), do: :session_not_started
  defp bridge_reason("invalid_recipient"), do: :invalid_recipient
  defp bridge_reason("unauthorized"), do: :unauthorized
  defp bridge_reason("forbidden"), do: :forbidden
  defp bridge_reason("banned"), do: :account_banned
  defp bridge_reason(_), do: :unknown
end
