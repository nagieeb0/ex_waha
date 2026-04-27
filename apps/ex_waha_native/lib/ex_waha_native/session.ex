defmodule ExWahaNative.Session do
  @moduledoc """
  Per-WhatsApp-account state machine.

  Holds the account, current status, and a set of subscribers (LiveViews,
  PubSub bridges, custom handlers) that get `{:ex_waha_native, kind, payload}`
  messages on every event from the Go bridge for this session.

  Outbound calls are routed through `ExWahaNative.Bridge`; this GenServer
  doesn't serialize them — the Bridge does.
  """

  use GenServer

  alias ExWahaNative.{Account, Bridge, Session}

  @type status :: :stopped | :starting | :scan_qr | :working | :failed

  defmodule State do
    @moduledoc false
    defstruct [:account, :status, :qr, :phone_number, :subscribers]
  end

  ## Client API

  def start_link(opts) do
    %Account{session: name} = Keyword.fetch!(opts, :account)
    GenServer.start_link(__MODULE__, opts, name: Session.Registry.via(name))
  end

  @spec status(String.t() | Account.t()) :: status()
  def status(%Account{session: name}), do: status(name)

  def status(name) when is_binary(name) do
    GenServer.call(Session.Registry.via(name), :status)
  end

  @spec subscribe(String.t() | Account.t(), pid()) :: :ok
  def subscribe(account_or_name, pid \\ self())

  def subscribe(%Account{session: name}, pid), do: subscribe(name, pid)

  def subscribe(name, pid) when is_binary(name) do
    GenServer.cast(Session.Registry.via(name), {:subscribe, pid})
  end

  @doc """
  Returns the most recent QR code seen for the session, or `nil` if none.

  When the account is unpaired, the bridge emits successive `qr` events as
  the underlying WhatsApp QR rotates every ~20s. This helper exposes the
  latest one so a controller/LiveView can render it without subscribing.
  """
  @spec qr(String.t() | Account.t()) :: String.t() | nil
  def qr(%Account{session: name}), do: qr(name)

  def qr(name) when is_binary(name) do
    GenServer.call(Session.Registry.via(name), :qr)
  end

  @doc """
  Request a phone-pairing code instead of QR.

  WhatsApp 2.24+ supports linking a device via a numeric pairing code shown
  on the phone. Returns `{:ok, code}` (formatted as e.g. `"ABCD-EFGH"`) or
  an `{:error, reason}` if the session is not in a state to pair.
  """
  @spec request_pairing_code(String.t() | Account.t(), String.t()) ::
          {:ok, String.t()} | {:error, term()}
  def request_pairing_code(%Account{session: name}, phone), do: request_pairing_code(name, phone)

  def request_pairing_code(name, phone) when is_binary(name) and is_binary(phone) do
    GenServer.call(Session.Registry.via(name), {:pair, phone}, 30_000)
  end

  @doc """
  Log the device out at the protocol level — wipes the paired session on
  the WhatsApp servers and clears local state. After this the next `start`
  triggers a fresh QR/pairing flow.
  """
  @spec logout(String.t() | Account.t()) :: :ok | {:error, term()}
  def logout(%Account{session: name}), do: logout(name)

  def logout(name) when is_binary(name) do
    GenServer.call(Session.Registry.via(name), :logout, 30_000)
  end

  @doc """
  Stop the session GenServer (closes the device locally but does not
  invalidate the WhatsApp pairing — `start` will reconnect).
  """
  @spec stop(String.t() | Account.t()) :: :ok
  def stop(%Account{session: name}), do: stop(name)

  def stop(name) when is_binary(name) do
    GenServer.call(Session.Registry.via(name), :close, 15_000)
  end

  @doc false
  @spec deliver_event(String.t(), map()) :: :ok
  def deliver_event(session, event) when is_binary(session) and is_map(event) do
    case Session.Registry.lookup(session) do
      {:ok, pid} -> send(pid, {:bridge_event, event})
      :error -> :ok
    end
  end

  ## Server

  @impl true
  def init(opts) do
    account = Keyword.fetch!(opts, :account)
    state = %State{account: account, status: :stopped, subscribers: MapSet.new()}

    if Keyword.get(opts, :auto_start, true) do
      {:ok, state, {:continue, :open_session}}
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_continue(:open_session, %State{account: account} = state) do
    args = %{
      session: account.session,
      store: serialize_store(account.store)
    }

    case Bridge.call(account.bridge, account.session, "open_session", args) do
      {:ok, %{"status" => status}} ->
        {:noreply, %{state | status: parse_status(status)}}

      {:error, _reason} ->
        {:noreply, %{state | status: :failed}}
    end
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, state.status, state}

  def handle_call(:qr, _from, state), do: {:reply, state.qr, state}

  def handle_call({:pair, phone}, _from, %State{account: account} = state) do
    args = %{phone: phone}

    case Bridge.call(account.bridge, account.session, "request_pairing_code", args) do
      {:ok, %{"code" => code}} ->
        {:reply, {:ok, code}, %{state | phone_number: phone}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:logout, _from, %State{account: account} = state) do
    case Bridge.call(account.bridge, account.session, "logout", %{}) do
      {:ok, _} -> {:reply, :ok, %{state | status: :stopped, qr: nil, phone_number: nil}}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:close, _from, %State{account: account} = state) do
    _ = Bridge.call(account.bridge, account.session, "close_session", %{})
    {:reply, :ok, %{state | status: :stopped, qr: nil}}
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    Process.monitor(pid)
    {:noreply, %{state | subscribers: MapSet.put(state.subscribers, pid)}}
  end

  @impl true
  def handle_info({:bridge_event, %{"kind" => kind, "payload" => payload}}, state) do
    state = update_state_from_event(state, kind, payload)
    notify(state.subscribers, kind, payload)
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, %{state | subscribers: MapSet.delete(state.subscribers, pid)}}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  ## Internal

  defp update_state_from_event(state, "qr", %{"code" => code}) do
    %{state | status: :scan_qr, qr: code}
  end

  defp update_state_from_event(state, "paired", %{"phone" => phone}) do
    %{state | status: :working, phone_number: phone, qr: nil}
  end

  defp update_state_from_event(state, "disconnected", _), do: %{state | status: :stopped}
  defp update_state_from_event(state, _kind, _payload), do: state

  defp notify(subscribers, kind, payload) do
    Enum.each(subscribers, fn pid ->
      send(pid, {:ex_waha_native, String.to_existing_atom(kind), payload})
    end)
  rescue
    ArgumentError ->
      Enum.each(subscribers, fn pid -> send(pid, {:ex_waha_native, :unknown, payload}) end)
  end

  defp parse_status("WORKING"), do: :working
  defp parse_status("SCAN_QR"), do: :scan_qr
  defp parse_status("STARTING"), do: :starting
  defp parse_status("FAILED"), do: :failed
  defp parse_status(_), do: :stopped

  defp serialize_store(nil), do: %{kind: "memory"}
  defp serialize_store({:sqlite, path}), do: %{kind: "sqlite", path: path}
  defp serialize_store({:postgres, opts}), do: %{kind: "postgres", opts: Map.new(opts)}
end
