defmodule ExWahaNative.BridgeSmokeTest do
  @moduledoc """
  End-to-end smoke test: start the Bridge GenServer pointing at the actual
  Go binary, send a ping, assert pong.

  Skipped if the binary hasn't been built. Run `mix ex_waha_native.build_native`
  first.
  """
  use ExUnit.Case, async: false

  alias ExWahaNative.Bridge

  @binary_path Path.join([File.cwd!(), "priv", "native", "whatsmeow_bridge"])

  setup do
    if File.exists?(@binary_path) do
      {:ok, pid} = Bridge.start_link(name: nil, binary_path: @binary_path)
      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)
      {:ok, bridge: pid}
    else
      :ok
    end
  end

  @tag :smoke
  test "ping op returns pong with the session", ctx do
    if pid = ctx[:bridge] do
      assert {:ok, %{"pong" => "p_test"}} = Bridge.call(pid, "p_test", "ping", %{})
    else
      IO.puts("\nskipping — Go binary not built at #{@binary_path}")
    end
  end

  @tag :smoke
  test "unknown op returns an error frame", ctx do
    if pid = ctx[:bridge] do
      result = Bridge.call(pid, "p_test", "definitely_not_a_real_op", %{})
      assert {:error, {"unknown_op", _}} = result
    else
      IO.puts("\nskipping — Go binary not built at #{@binary_path}")
    end
  end
end
