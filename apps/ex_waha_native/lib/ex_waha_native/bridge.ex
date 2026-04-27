defmodule ExWahaNative.Bridge do
  @moduledoc """
  GenServer that owns the Go bridge `Port` and routes traffic between
  Elixir callers and the whatsmeow process.

    * Outbound: serializes `%{op, args}` requests to length-prefixed JSON,
      stores `ref -> from` for the reply.
    * Inbound: stream-decodes frames; routes `response` to the awaiting
      caller, dispatches `event` to the session GenServer.

  ## Crash semantics

  If the Port closes (Go process died), this GenServer exits. Its supervisor
  restarts it, which re-spawns the Go binary. whatsmeow re-connects every
  session from sqlstore. In-flight requests get `{:error, :bridge_restart}`.
  """

  use GenServer

  alias ExWahaNative.{Session, Wire}

  require Logger

  defmodule State do
    @moduledoc false
    defstruct [:port, :buffer, :pending, :binary_path]
  end

  ## Client API

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Synchronously send a request to the Go bridge and await its response.
  """
  @spec call(GenServer.name(), String.t(), String.t(), map(), timeout()) ::
          {:ok, any()} | {:error, term()}
  def call(server \\ __MODULE__, session, op, args, timeout \\ 30_000) do
    GenServer.call(server, {:request, session, op, args}, timeout)
  end

  @doc "Fire-and-forget op."
  @spec cast(GenServer.name(), String.t(), String.t(), map()) :: :ok
  def cast(server \\ __MODULE__, session, op, args) do
    GenServer.cast(server, {:cast, session, op, args})
  end

  ## Server

  @impl true
  def init(opts) do
    binary = Keyword.get(opts, :binary_path, default_binary_path())
    state = %State{port: nil, buffer: <<>>, pending: %{}, binary_path: binary}
    {:ok, state, {:continue, :open}}
  end

  @impl true
  def handle_continue(:open, %State{binary_path: path} = state) do
    case open_port(path) do
      {:ok, port} ->
        {:noreply, %{state | port: port}}

      {:error, reason} ->
        Logger.error("ExWahaNative.Bridge could not open #{path}: #{inspect(reason)}")
        {:stop, {:bridge_open_failed, reason}, state}
    end
  end

  @impl true
  def handle_call({:request, session, op, args}, from, %State{port: port} = state)
      when is_port(port) do
    ref = Wire.new_ref()
    frame = Wire.encode!(%{type: "request", ref: ref, session: session, op: op, args: args})
    Port.command(port, frame)
    pending = Map.put(state.pending, ref, from)
    {:noreply, %{state | pending: pending}}
  end

  def handle_call({:request, _session, _op, _args}, _from, state) do
    {:reply, {:error, :bridge_not_ready}, state}
  end

  @impl true
  def handle_cast({:cast, session, op, args}, %State{port: port} = state) when is_port(port) do
    frame = Wire.encode!(%{type: "request", ref: nil, session: session, op: op, args: args})
    Port.command(port, frame)
    {:noreply, state}
  end

  def handle_cast(_msg, state), do: {:noreply, state}

  @impl true
  def handle_info({port, {:data, bytes}}, %State{port: port} = state) do
    {messages, buffer} = Wire.decode_stream(state.buffer <> bytes)
    pending = Enum.reduce(messages, state.pending, &dispatch/2)
    {:noreply, %{state | buffer: buffer, pending: pending}}
  end

  def handle_info({port, {:exit_status, status}}, %State{port: port} = state) do
    Logger.error("Bridge exited with status #{status}")
    fail_pending(state.pending, :bridge_exited)
    {:stop, {:bridge_exit, status}, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, %State{port: port, pending: pending}) do
    fail_pending(pending, :bridge_terminating)
    if is_port(port), do: Port.close(port)
    :ok
  end

  ## Internal

  defp open_port(path) do
    if File.exists?(path) do
      port =
        Port.open(
          {:spawn_executable, path},
          [:binary, :exit_status, :use_stdio]
        )

      {:ok, port}
    else
      {:error, {:not_found, path}}
    end
  end

  defp dispatch(%{"type" => "response", "ref" => ref} = msg, pending) do
    case Map.pop(pending, ref) do
      {nil, pending} ->
        Logger.warning("response with unknown ref: #{ref}")
        pending

      {from, pending} ->
        reply = if msg["ok"], do: {:ok, msg["result"]}, else: {:error, error_from(msg)}
        GenServer.reply(from, reply)
        pending
    end
  end

  defp dispatch(%{"type" => "event", "session" => session} = event, pending) do
    Session.deliver_event(session, event)
    pending
  end

  defp dispatch(other, pending) do
    Logger.warning("unknown bridge frame: #{inspect(other)}")
    pending
  end

  defp error_from(%{"error" => message, "code" => code}), do: {code, message}
  defp error_from(%{"error" => message}), do: {nil, message}
  defp error_from(_), do: {nil, "unknown bridge error"}

  defp fail_pending(pending, reason) do
    Enum.each(pending, fn {_ref, from} -> GenServer.reply(from, {:error, reason}) end)
  end

  defp default_binary_path do
    Application.app_dir(:ex_waha_native, ["priv", "native", "whatsmeow_bridge"])
  end
end
