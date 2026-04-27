defmodule ExWaha.Session.ServerTest do
  use ExUnit.Case, async: false

  import ExWaha.Test.Factories

  alias ExWaha.Session.{Server, Supervisor}

  setup do
    account = waha_account(session: "lifecycle_#{System.unique_integer([:positive])}")
    on_exit(fn -> Supervisor.stop(account) end)
    {:ok, account: account}
  end

  test "starts in :stopped status", %{account: account} do
    {:ok, pid} = Supervisor.ensure_started(account)
    assert Server.status(pid) == :stopped
  end

  test "reserve refuses while not :working", %{account: account} do
    {:ok, pid} = Supervisor.ensure_started(account)
    result = Server.gated_call(pid, fn -> {:ok, :sent} end)
    assert {:error, %ExWaha.Error{reason: :session_not_started}} = result
  end

  test "reserve allows when status is :working", %{account: account} do
    {:ok, pid} = Supervisor.ensure_started(account)
    Server.set_status(pid, :working)
    # Wait for cast
    _ = Server.status(pid)
    assert {:ok, :sent} = Server.gated_call(pid, fn -> {:ok, :sent} end)
  end

  test "subscribers get status notifications", %{account: account} do
    {:ok, pid} = Supervisor.ensure_started(account)
    Server.subscribe(pid, self())
    Server.set_status(pid, :scan_qr)
    assert_receive {:ex_waha_status, _account, :scan_qr}, 500
  end
end
