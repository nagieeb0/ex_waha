defmodule ExWaha.Session.Supervisor do
  @moduledoc """
  DynamicSupervisor for per-account `ExWaha.Session.Server` processes.
  """

  use DynamicSupervisor

  alias ExWaha.Session

  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts), do: DynamicSupervisor.init(strategy: :one_for_one)

  @doc """
  Start (or look up) the session server for an account. Idempotent.
  """
  @spec ensure_started(struct(), keyword()) :: {:ok, pid()} | {:error, term()}
  def ensure_started(account, opts \\ []) do
    case Session.Registry.lookup(account) do
      {:ok, pid} ->
        {:ok, pid}

      :error ->
        spec = {Session.Server, [account: account] ++ opts}

        case DynamicSupervisor.start_child(__MODULE__, spec) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          other -> other
        end
    end
  end

  @spec stop(struct()) :: :ok | {:error, :not_found}
  def stop(account) do
    case Session.Registry.lookup(account) do
      {:ok, pid} -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      :error -> {:error, :not_found}
    end
  end
end
