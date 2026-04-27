defmodule ExWahaNative.ProviderRegistrationTest do
  use ExUnit.Case, async: false

  test "ExWaha.Provider dispatches Account to ExWahaNative.Provider" do
    account = ExWahaNative.Account.new(session: "p")
    assert ExWaha.Provider.provider_for!(account) == ExWahaNative.Provider
  end
end
