defmodule ExWaha.Api.Profile do
  @moduledoc "WAHA profile endpoints."

  import ExWaha.Api.Helpers

  alias ExWaha.Providers.Waha.Account

  @spec me(Account.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def me(%Account{instance: inst, session: s}) do
    request(inst, :get, "/api/" <> s <> "/profile", nil)
  end

  @spec set_name(Account.t(), String.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def set_name(%Account{instance: inst, session: s}, name) do
    request(inst, :put, "/api/" <> s <> "/profile/name", %{name: name})
  end

  @spec set_status(Account.t(), String.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def set_status(%Account{instance: inst, session: s}, status) do
    request(inst, :put, "/api/" <> s <> "/profile/status", %{status: status})
  end
end
