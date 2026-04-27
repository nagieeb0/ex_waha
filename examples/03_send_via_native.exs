# Send via the native Go bridge (no WAHA server, no Meta account).
#
# This boots an `ExWahaNative.Session`, prints the QR string for first-time
# pairing, and sends a text once the session reaches `:working` status.
#
# Usage:
#   mix ex_waha_native.build_native        # builds priv/native/whatsmeow_bridge
#   export NATIVE_RECIPIENT="+201001234567"
#   mix run examples/03_send_via_native.exs
#
# State persists in `apps/ex_waha_native/priv/sessions/<session>.db`, so
# subsequent runs reconnect without re-pairing.

recipient = System.fetch_env!("NATIVE_RECIPIENT")

session = "demo"
db_path = Path.join(["apps", "ex_waha_native", "priv", "sessions", "#{session}.db"])

account =
  %ExWahaNative.Account{
    session: session,
    store: {:sqlite, db_path},
    bridge: ExWahaNative.Bridge
  }

{:ok, _pid} = ExWahaNative.Session.Supervisor.ensure_started(account)
ExWahaNative.Session.subscribe(account)

IO.puts("Waiting for session #{session} to reach :working ...")

defmodule Demo do
  def wait_until_working(account, timeout_ms \\ 120_000) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    loop(account, deadline)
  end

  defp loop(account, deadline) do
    receive do
      {:ex_waha_native, :qr, %{"code" => code}} ->
        IO.puts("\nSCAN THIS QR with WhatsApp -> Linked devices:\n#{code}\n")
        loop(account, deadline)

      {:ex_waha_native, :paired, payload} ->
        IO.inspect(payload, label: "PAIRED")
        loop(account, deadline)

      {:ex_waha_native, :connected, _} ->
        :ok
    after
      1_000 ->
        cond do
          ExWahaNative.Session.status(account) == :working -> :ok
          System.monotonic_time(:millisecond) > deadline -> {:error, :timeout}
          true -> loop(account, deadline)
        end
    end
  end
end

case Demo.wait_until_working(account) do
  :ok ->
    IO.puts("\nSession is :working — sending message")

    case ExWaha.send_text(account, recipient, "Hello from ex_waha_native 🚀") do
      {:ok, body} -> IO.inspect(body, label: "TEXT OK")
      {:error, err} -> IO.inspect(err, label: "TEXT ERROR")
    end

  other ->
    IO.inspect(other, label: "PAIRING FAILED")
end
