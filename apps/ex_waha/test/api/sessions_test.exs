defmodule ExWaha.Api.SessionsTest do
  use ExUnit.Case, async: true

  import Mox
  import ExWaha.Test.Factories

  alias ExWaha.Api.Sessions

  setup :verify_on_exit!

  test "create posts session config" do
    account = waha_account()

    ExWaha.ClientMock
    |> expect(:request, fn :post, url, _h, body, _o ->
      assert url =~ "/api/sessions"
      assert body.name == "profile_test"
      assert body.start == true
      {:ok, %{status: 201, headers: [], body: %{"name" => body.name}}}
    end)

    assert {:ok, %{"name" => "profile_test"}} = Sessions.create(account, %{})
  end

  test "start hits /api/sessions/:name/start" do
    account = waha_account()

    ExWaha.ClientMock
    |> expect(:request, fn :post, url, _h, _b, _o ->
      assert url =~ "/api/sessions/profile_test/start"
      {:ok, %{status: 200, headers: [], body: %{}}}
    end)

    assert {:ok, _} = Sessions.start(account)
  end

  test "stop hits /api/sessions/:name/stop" do
    account = waha_account()

    ExWaha.ClientMock
    |> expect(:request, fn :post, url, _h, _b, _o ->
      assert url =~ "/api/sessions/profile_test/stop"
      {:ok, %{status: 200, headers: [], body: %{}}}
    end)

    assert {:ok, _} = Sessions.stop(account)
  end
end
