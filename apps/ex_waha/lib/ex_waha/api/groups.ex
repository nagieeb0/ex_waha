defmodule ExWaha.Api.Groups do
  @moduledoc "WAHA group endpoints."

  import ExWaha.Api.Helpers

  alias ExWaha.Providers.Waha.Account

  @spec list(Account.t()) :: {:ok, [map()]} | {:error, ExWaha.Error.t()}
  def list(%Account{instance: inst, session: s}) do
    request(inst, :get, "/api/" <> s <> "/groups", nil)
  end

  @spec get(Account.t(), String.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def get(%Account{instance: inst, session: s}, group_id) do
    request(inst, :get, "/api/#{s}/groups/#{group_id}", nil)
  end

  @spec create(Account.t(), String.t(), [String.t()]) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def create(%Account{instance: inst, session: s}, name, participants) do
    body = %{name: name, participants: Enum.map(participants, &%{id: &1})}
    request(inst, :post, "/api/" <> s <> "/groups", body)
  end

  @spec add_participants(Account.t(), String.t(), [String.t()]) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def add_participants(%Account{instance: inst, session: s}, group_id, participants) do
    body = %{participants: Enum.map(participants, &%{id: &1})}
    request(inst, :post, "/api/#{s}/groups/#{group_id}/participants/add", body)
  end

  @spec remove_participants(Account.t(), String.t(), [String.t()]) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def remove_participants(%Account{instance: inst, session: s}, group_id, participants) do
    body = %{participants: Enum.map(participants, &%{id: &1})}
    request(inst, :post, "/api/#{s}/groups/#{group_id}/participants/remove", body)
  end

  @spec leave(Account.t(), String.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def leave(%Account{instance: inst, session: s}, group_id) do
    request(inst, :post, "/api/#{s}/groups/#{group_id}/leave", %{})
  end
end
