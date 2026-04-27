defmodule ExWahaNative.Account do
  @moduledoc """
  An account on the native (whatsmeow) provider.

  Unlike `ExWaha.Providers.Waha.Account` there is no remote server URL;
  the Go binary runs locally inside the BEAM node. Sessions are identified
  by their `session_name`.
  """

  @enforce_keys [:session]
  defstruct [
    :session,
    :store,
    bridge: ExWahaNative.Bridge
  ]

  @type t :: %__MODULE__{
          session: String.t(),
          store: nil | {:sqlite, String.t()} | {:postgres, keyword()},
          bridge: GenServer.name()
        }

  @spec new(keyword()) :: t()
  def new(opts) do
    struct!(__MODULE__, opts)
  end
end
