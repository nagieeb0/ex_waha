defmodule ExWaha.Session.Registry do
  @moduledoc """
  Process registry for `ExWaha.Session.Server` instances.

  Registry key is a stable `{provider, account_key}` tuple so the same logical
  account always resolves to the same server — even across restarts.
  """

  alias ExWaha.Providers

  @registry __MODULE__

  @spec via(struct()) :: {:via, Registry, {module(), term()}}
  def via(account), do: {:via, Registry, {@registry, key(account)}}

  @spec lookup(struct()) :: {:ok, pid()} | :error
  def lookup(account) do
    case Registry.lookup(@registry, key(account)) do
      [{pid, _}] -> {:ok, pid}
      [] -> :error
    end
  end

  @spec key(struct()) :: term()
  def key(%Providers.Waha.Account{instance: %{base_url: url}, session: session}) do
    {:waha, url, session}
  end

  def key(%Providers.Meta.Account{phone_number_id: pn_id}) do
    {:meta, pn_id}
  end
end
