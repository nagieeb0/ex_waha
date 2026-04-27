defmodule ExWaha.Providers.Waha.Account do
  @moduledoc """
  An account on a specific WAHA server.

  Combines:

    * `instance` — `%ExWaha.Instance{}` (server connection details)
    * `session` — WAHA session name, typically derived from your tenant id
      (e.g. `"profile_42"`)
    * `webhook_secret` — optional HMAC-SHA512 secret WAHA was configured with
  """

  alias ExWaha.Instance

  @enforce_keys [:instance, :session]
  defstruct [:instance, :session, :webhook_secret]

  @type t :: %__MODULE__{
          instance: Instance.t(),
          session: String.t(),
          webhook_secret: nil | String.t()
        }

  @spec new(Instance.t(), String.t(), keyword()) :: t()
  def new(%Instance{} = instance, session, opts \\ []) when is_binary(session) do
    %__MODULE__{
      instance: instance,
      session: session,
      webhook_secret: Keyword.get(opts, :webhook_secret)
    }
  end
end
