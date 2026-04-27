defmodule ExWahaNative.Session.Registry do
  @moduledoc "Process registry for `ExWahaNative.Session` instances, keyed by session name."

  @registry __MODULE__

  @spec via(String.t()) :: {:via, Registry, {module(), String.t()}}
  def via(session) when is_binary(session), do: {:via, Registry, {@registry, session}}

  @spec lookup(String.t()) :: {:ok, pid()} | :error
  def lookup(session) when is_binary(session) do
    case Registry.lookup(@registry, session) do
      [{pid, _}] -> {:ok, pid}
      [] -> :error
    end
  end
end
