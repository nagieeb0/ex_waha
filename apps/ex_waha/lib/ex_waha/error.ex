defmodule ExWaha.Error do
  @moduledoc """
  Normalized error returned by every ExWaha call.

  Reasons:

    * `:rate_limited` — local token bucket refused the call (back off and retry).
    * `:session_not_started` — provider session is not in a sendable state.
    * `:invalid_recipient` — recipient is not on WhatsApp or wrong format.
    * `:unauthorized` — bad API key / access token.
    * `:forbidden` — likely policy violation (template required, 24h window).
    * `:account_banned` — provider says this number is banned.
    * `:network` — transport failure (timeout, DNS, etc.).
    * `:server_error` — provider returned 5xx.
    * `:unknown` — fallback.
  """

  @type reason ::
          :rate_limited
          | :session_not_started
          | :invalid_recipient
          | :unauthorized
          | :forbidden
          | :account_banned
          | :network
          | :server_error
          | :unknown

  @type t :: %__MODULE__{
          reason: reason(),
          message: String.t(),
          status: nil | non_neg_integer(),
          body: any(),
          retry_after_ms: nil | non_neg_integer()
        }

  defexception [:reason, :message, :status, :body, :retry_after_ms]

  @impl true
  def exception(opts) when is_list(opts) do
    struct!(__MODULE__, Keyword.put_new(opts, :message, "ExWaha error: #{opts[:reason]}"))
  end

  @spec from_status(non_neg_integer(), any()) :: t()
  def from_status(status, body) do
    reason =
      case status do
        401 -> :unauthorized
        403 -> :forbidden
        404 -> :invalid_recipient
        422 -> :invalid_recipient
        429 -> :rate_limited
        s when s in 500..599 -> :server_error
        _ -> :unknown
      end

    exception(reason: reason, status: status, body: body, message: "HTTP #{status}")
  end
end
