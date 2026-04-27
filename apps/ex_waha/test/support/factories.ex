defmodule ExWaha.Test.Factories do
  @moduledoc false

  alias ExWaha.{Instance, Providers.Meta, Providers.Waha}

  def waha_instance(overrides \\ []) do
    Instance.new([base_url: "http://waha.test", api_key: "test_key"] ++ overrides)
  end

  def waha_account(overrides \\ []) do
    instance = Keyword.get(overrides, :instance, waha_instance())
    session = Keyword.get(overrides, :session, "profile_test")
    Waha.Account.new(instance, session, webhook_secret: "shhh")
  end

  def meta_account(overrides \\ []) do
    Meta.Account.new(
      [
        phone_number_id: "111",
        access_token: "tok",
        app_secret: "secret"
      ] ++ overrides
    )
  end
end
