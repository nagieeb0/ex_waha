defmodule ExWahaNative.Session.Supervisor do
  @moduledoc "DynamicSupervisor for per-account `ExWahaNative.Session` processes."

  use DynamicSupervisor

  alias ExWahaNative.{Account, Session}

  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts), do: DynamicSupervisor.init(strategy: :one_for_one)

  @spec ensure_started(Account.t(), keyword()) :: {:ok, pid()} | {:error, term()}
  def ensure_started(%Account{session: name} = account, opts \\ []) do
    case Session.Registry.lookup(name) do
      {:ok, pid} ->
        {:ok, pid}

      :error ->
        spec = {Session, [account: account] ++ opts}

        case DynamicSupervisor.start_child(__MODULE__, spec) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          other -> other
        end
    end
  end

  @spec stop(Account.t()) :: :ok | {:error, :not_found}
  def stop(%Account{session: name}) do
    case Session.Registry.lookup(name) do
      {:ok, pid} -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      :error -> {:error, :not_found}
    end
  end
end
