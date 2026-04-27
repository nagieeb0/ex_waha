defmodule ExWaha.Instance do
  @moduledoc """
  Configuration for a single WAHA server.

  An `Instance` describes how to reach a WAHA Docker container. Multiple
  instances coexist — pass the right one per call. No global state.
  """

  @enforce_keys [:base_url]
  defstruct [
    :base_url,
    :api_key,
    :http_client,
    timeout_ms: 10_000,
    receive_timeout_ms: 30_000,
    headers: []
  ]

  @type t :: %__MODULE__{
          base_url: String.t(),
          api_key: nil | String.t(),
          http_client: nil | module(),
          timeout_ms: pos_integer(),
          receive_timeout_ms: pos_integer(),
          headers: [{String.t(), String.t()}]
        }

  @doc """
  Build an `Instance` from keyword opts.

  ## Required

    * `:base_url` — full URL to the WAHA server (e.g. `"http://waha:3000"`)

  ## Optional

    * `:api_key` — `X-Api-Key` header value (set if WAHA was started with one)
    * `:http_client` — module implementing `ExWaha.Client` (defaults to
      `ExWaha.Client.Req` via application config)
    * `:timeout_ms` — connect timeout (default `10_000`)
    * `:receive_timeout_ms` — response timeout (default `30_000`)
    * `:headers` — additional request headers (default `[]`)

  ## Example

      ExWaha.Instance.new(
        base_url: "http://waha.internal:3000",
        api_key: System.fetch_env!("WAHA_API_KEY")
      )
  """
  @spec new(keyword()) :: t()
  def new(opts) do
    struct!(__MODULE__, opts)
  end
end
