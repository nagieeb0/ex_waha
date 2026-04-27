defmodule ExWahaNative.KeyableTest do
  use ExUnit.Case, async: true

  alias ExWaha.Session.{Keyable, Registry}

  test "Keyable returns {:native, session} for native accounts" do
    account = ExWahaNative.Account.new(session: "profile_42")
    assert Keyable.key(account) == {:native, "profile_42"}
  end

  test "Session.Registry.key/1 delegates to Keyable for native accounts" do
    account = ExWahaNative.Account.new(session: "profile_99")
    assert Registry.key(account) == {:native, "profile_99"}
  end

  test "ExWaha.send_text on a native account reaches the bridge dispatch path" do
    # Before the Keyable fix, this returned {:error, %Error{reason: :unknown}}
    # because Session.Registry.key/1 raised FunctionClauseError, caught by
    # SafeSend's `rescue`. After the fix, lookup returns :error, SafeSend
    # falls through to fun.(), which calls Bridge.call/4 — and that exits
    # with :noproc because no Bridge GenServer is started in this test env.
    # The exit (rather than the silent :unknown return) proves we now reach
    # the real send path.
    account = ExWahaNative.Account.new(session: "profile_test_unstarted")

    assert {:noproc, _} =
             catch_exit(ExWaha.send_text(account, "+201001234567", "hi"))
  end
end
