defmodule ExWaha.SafeSend do
  @moduledoc """
  The single gate every outbound message must pass through.

  Responsibilities:

    1. Locate (or skip) the per-account `ExWaha.Session.Server`.
    2. Check the rate-limit token bucket.
    3. Verify the session is in a sendable state.
    4. Apply randomized jitter (ban-risk mitigation).
    5. Emit telemetry on throttle and dispatch.

  If no session server is registered for the account (e.g. tests, or an app
  that hasn't started one), `dispatch/2` falls through to the inner function
  without limits — explicit opt-in to safety via the OTP layer.
  """

  alias ExWaha.{Error, Session, Telemetry}

  @type result :: {:ok, any()} | {:error, Error.t()}

  @spec dispatch(struct(), (-> result())) :: result()
  def dispatch(account, fun) when is_function(fun, 0) do
    case Session.Registry.lookup(account) do
      {:ok, pid} ->
        Session.Server.gated_call(pid, fun)

      :error ->
        # No session server registered — bypassing the safety layer.
        # Allowed but discouraged outside tests.
        fun.()
    end
  rescue
    e ->
      msg = Exception.message(e)
      {:error, Error.exception(reason: :unknown, message: msg, body: e)}
  end

  @spec sleep_jitter(non_neg_integer()) :: :ok
  def sleep_jitter(0), do: :ok

  def sleep_jitter(ms) when is_integer(ms) and ms > 0 do
    Telemetry.emit([:rate_limit, :jitter], %{ms: ms}, %{})
    Process.sleep(ms)
  end
end
