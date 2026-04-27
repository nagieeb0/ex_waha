defmodule ExWaha.Session.Registry do
  @moduledoc """
  Process registry for `ExWaha.Session.Server` instances.

  Registry key is a stable `{provider, account_key}` tuple so the same logical
  account always resolves to the same server — even across restarts.

  The per-account-struct mapping is provided by `ExWaha.Session.Keyable`,
  which external provider apps implement for their own account structs.
  """

  alias ExWaha.Session.Keyable

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
  def key(account), do: Keyable.key(account)
end
