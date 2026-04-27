defmodule ExWaha.Api.Chats do
  @moduledoc "WAHA chat endpoints."

  import ExWaha.Api.Helpers

  alias ExWaha.{Recipient, Providers.Waha.Account}

  @spec list(Account.t(), keyword()) :: {:ok, [map()]} | {:error, ExWaha.Error.t()}
  def list(%Account{instance: inst, session: s}, opts \\ []) do
    qs =
      opts
      |> Keyword.take([:limit, :offset])
      |> URI.encode_query()

    sep = if qs == "", do: "", else: "?"
    request(inst, :get, "/api/" <> s <> "/chats" <> sep <> qs, nil)
  end

  @spec messages(Account.t(), Recipient.t() | String.t(), keyword()) ::
          {:ok, [map()]} | {:error, ExWaha.Error.t()}
  def messages(%Account{instance: inst, session: s}, recipient, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    chat = Recipient.to_waha(normalize(recipient))
    request(inst, :get, "/api/#{s}/chats/#{chat}/messages?limit=#{limit}", nil)
  end

  @spec archive(Account.t(), Recipient.t() | String.t()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def archive(%Account{instance: inst, session: s}, recipient) do
    chat = Recipient.to_waha(normalize(recipient))
    request(inst, :post, "/api/#{s}/chats/#{chat}/archive", %{})
  end

  @spec delete(Account.t(), Recipient.t() | String.t()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def delete(%Account{instance: inst, session: s}, recipient) do
    chat = Recipient.to_waha(normalize(recipient))
    request(inst, :delete, "/api/#{s}/chats/#{chat}", nil)
  end

  defp normalize(%Recipient{} = r), do: r
  defp normalize(s) when is_binary(s), do: Recipient.new(s)
end
