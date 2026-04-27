defmodule ExWaha.Api.Contacts do
  @moduledoc "WAHA contact endpoints. Use `check_exists/2` BEFORE sending to unknowns."

  import ExWaha.Api.Helpers

  alias ExWaha.{Recipient, Providers.Waha.Account}

  @doc """
  Check whether a phone number is registered on WhatsApp.

  This is the single most important call to make before sending unsolicited
  outbound — sending to non-WhatsApp numbers is a strong ban signal.
  """
  @spec check_exists(Account.t(), String.t()) ::
          {:ok, %{exists: boolean(), chat_id: String.t() | nil}} | {:error, ExWaha.Error.t()}
  def check_exists(%Account{instance: inst, session: s}, phone) do
    digits = Recipient.new(phone).phone

    case request(inst, :get, "/api/contacts/check-exists?session=#{s}&phone=#{digits}", nil) do
      {:ok, %{"numberExists" => true} = body} ->
        {:ok, %{exists: true, chat_id: Map.get(body, "chatId")}}

      {:ok, %{"numberExists" => false}} ->
        {:ok, %{exists: false, chat_id: nil}}

      other ->
        other
    end
  end

  @spec get(Account.t(), Recipient.t() | String.t()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def get(%Account{instance: inst, session: s}, recipient) do
    chat = recipient |> normalize() |> Recipient.to_waha()
    request(inst, :get, "/api/contacts?contactId=#{chat}&session=#{s}", nil)
  end

  @spec profile_picture(Account.t(), Recipient.t() | String.t()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def profile_picture(%Account{instance: inst, session: s}, recipient) do
    chat = recipient |> normalize() |> Recipient.to_waha()
    request(inst, :get, "/api/contacts/profile-picture?contactId=#{chat}&session=#{s}", nil)
  end

  defp normalize(%Recipient{} = r), do: r
  defp normalize(s) when is_binary(s), do: Recipient.new(s)
end
