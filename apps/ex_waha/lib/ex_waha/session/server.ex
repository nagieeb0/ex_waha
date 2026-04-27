defmodule ExWaha.Session.Server do
  @moduledoc """
  Per-account state machine.

  Holds:

    * the account struct
    * status (`:stopped | :starting | :scan_qr | :working | :failed`)
    * a token-bucket rate limiter (sized by warmup age)
    * jitter config

  `gated_call/2` is the public API used by `ExWaha.SafeSend`. It serializes the
  rate-limit check (so two concurrent senders can't both consume the last
  token) but releases the GenServer before performing the HTTP call so the
  process is not the bottleneck.
  """

  use GenServer

  alias ExWaha.Error
  alias ExWaha.Safety.{RateLimiter, Warmup}
  alias ExWaha.{Session, Telemetry}

  @type status :: :stopped | :starting | :scan_qr | :working | :failed

  defmodule State do
    @moduledoc false
    defstruct [
      :account,
      :status,
      :bucket,
      :rate_config,
      :account_started_at,
      :last_status_change,
      :webhook_subscribers
    ]
  end

  ## Client API

  def start_link(opts) do
    account = Keyword.fetch!(opts, :account)
    GenServer.start_link(__MODULE__, opts, name: Session.Registry.via(account))
  end

  @doc "Block until rate limit allows, then run `fun` outside the GenServer."
  @spec gated_call(pid() | GenServer.name(), (-> any()), timeout()) :: any()
  def gated_call(server, fun, timeout \\ 60_000) do
    case GenServer.call(server, :reserve, timeout) do
      {:ok, jitter_ms} ->
        ExWaha.SafeSend.sleep_jitter(jitter_ms)
        result = fun.()
        GenServer.cast(server, {:released, result_outcome(result)})
        result

      {:throttle, ms_to_wait} ->
        Telemetry.emit([:rate_limit, :throttled], %{wait_ms: ms_to_wait}, %{})
        {:error, rate_limit_error(ms_to_wait)}

      {:not_ready, status} ->
        {:error, not_ready_error(status)}
    end
  end

  @spec status(pid() | GenServer.name()) :: status()
  def status(server), do: GenServer.call(server, :status)

  @spec set_status(pid() | GenServer.name(), status()) :: :ok
  def set_status(server, status), do: GenServer.cast(server, {:set_status, status})

  @spec subscribe(pid() | GenServer.name(), pid()) :: :ok
  def subscribe(server, pid \\ self()), do: GenServer.cast(server, {:subscribe, pid})

  ## Server

  @impl true
  def init(opts) do
    account = Keyword.fetch!(opts, :account)
    config = Application.get_env(:ex_waha, :rate_limit, [])
    started_at = Keyword.get(opts, :account_started_at, DateTime.utc_now())

    {capacity, refill} = Warmup.params(age_days(started_at), config)

    state = %State{
      account: account,
      status: Keyword.get(opts, :initial_status, :stopped),
      bucket: RateLimiter.new(capacity, refill),
      rate_config: config,
      account_started_at: started_at,
      last_status_change: System.system_time(:second),
      webhook_subscribers: MapSet.new()
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:reserve, _from, %State{status: status} = state)
      when status in [:stopped, :starting, :scan_qr, :failed] do
    {:reply, {:not_ready, status}, state}
  end

  def handle_call(:reserve, _from, %State{} = state) do
    case RateLimiter.take(state.bucket, 1) do
      {:ok, bucket} ->
        jitter = Warmup.random_jitter_ms(state.rate_config)
        {:reply, {:ok, jitter}, %{state | bucket: bucket}}

      {:error, ms_to_wait, bucket} ->
        {:reply, {:throttle, ms_to_wait}, %{state | bucket: bucket}}
    end
  end

  def handle_call(:status, _from, state), do: {:reply, state.status, state}

  @impl true
  def handle_cast({:set_status, new_status}, state) do
    if new_status != state.status do
      emit_status_change(state.account, state.status, new_status)
      notify_subscribers(state.webhook_subscribers, state.account, new_status)
    end

    now = System.system_time(:second)
    {:noreply, %{state | status: new_status, last_status_change: now}}
  end

  def handle_cast({:released, _outcome}, state), do: {:noreply, state}

  def handle_cast({:subscribe, pid}, state) do
    Process.monitor(pid)
    subs = MapSet.put(state.webhook_subscribers, pid)
    {:noreply, %{state | webhook_subscribers: subs}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    subs = MapSet.delete(state.webhook_subscribers, pid)
    {:noreply, %{state | webhook_subscribers: subs}}
  end

  defp age_days(%DateTime{} = dt) do
    div(DateTime.diff(DateTime.utc_now(), dt, :second), 86_400)
  end

  defp age_days(_), do: 0

  defp result_outcome({:ok, _}), do: :ok
  defp result_outcome({:error, _}), do: :error
  defp result_outcome(_), do: :unknown

  defp rate_limit_error(ms) do
    Error.exception(reason: :rate_limited, message: "rate limited", retry_after_ms: ms)
  end

  defp not_ready_error(status) do
    Error.exception(reason: :session_not_started, message: "session is #{status}")
  end

  defp emit_status_change(account, from, to) do
    Telemetry.emit(
      [:session, :status_changed],
      %{},
      %{from: from, to: to, account: Session.Registry.key(account)}
    )
  end

  defp notify_subscribers(subs, account, status) do
    Enum.each(subs, fn pid -> send(pid, {:ex_waha_status, account, status}) end)
  end
end
