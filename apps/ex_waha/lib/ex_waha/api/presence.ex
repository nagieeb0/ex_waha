defmodule ExWaha.Api.Presence do
  @moduledoc "WAHA presence endpoints."

  import ExWaha.Api.Helpers

  alias ExWaha.{Recipient, Providers.Waha.Account}

  @spec set(Account.t(), :online | :offline) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def set(%Account{instance: inst, session: s}, presence) do
    request(inst, :post, "/api/" <> s <> "/presence", %{presence: Atom.to_string(presence)})
  end

  @spec start_typing(Account.t(), Recipient.t() | String.t()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def start_typing(%Account{instance: inst, session: s}, recipient) do
    chat = recipient |> normalize() |> Recipient.to_waha()
    request(inst, :post, "/api/startTyping", %{chatId: chat, session: s})
  end

  @spec stop_typing(Account.t(), Recipient.t() | String.t()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def stop_typing(%Account{instance: inst, session: s}, recipient) do
    chat = recipient |> normalize() |> Recipient.to_waha()
    request(inst, :post, "/api/stopTyping", %{chatId: chat, session: s})
  end

  defp normalize(%Recipient{} = r), do: r
  defp normalize(s) when is_binary(s), do: Recipient.new(s)
end
