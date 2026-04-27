defmodule ExWahaNative.AccountTest do
  use ExUnit.Case, async: true

  alias ExWahaNative.Account

  test "new/1 builds with required session" do
    a = Account.new(session: "profile_42")
    assert a.session == "profile_42"
    assert a.bridge == ExWahaNative.Bridge
    assert a.store == nil
  end

  test "new/1 accepts a sqlite store tuple" do
    a = Account.new(session: "p", store: {:sqlite, "/tmp/p.db"})
    assert a.store == {:sqlite, "/tmp/p.db"}
  end

  test "raises if session is missing" do
    assert_raise ArgumentError, fn -> Account.new([]) end
  end
end
