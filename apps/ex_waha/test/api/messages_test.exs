defmodule ExWaha.Api.MessagesTest do
  use ExUnit.Case, async: true

  import Mox
  import ExWaha.Test.Factories

  alias ExWaha.Api.Messages

  setup :verify_on_exit!

  describe "send_text/4" do
    test "posts to /api/sendText with WAHA chat id" do
      account = waha_account()

      ExWaha.ClientMock
      |> expect(:request, fn :post, url, headers, body, _opts ->
        assert url =~ "/api/sendText"
        assert {"x-api-key", "test_key"} in headers
        assert body.chatId == "201001234567@c.us"
        assert body.text == "hi"
        assert body.session == "profile_test"
        {:ok, %{status: 201, headers: [], body: %{"id" => "msg_1"}}}
      end)

      assert {:ok, %{"id" => "msg_1"}} =
               Messages.send_text(account, "+20 100 123 4567", "hi")
    end

    test "maps 401 to :unauthorized" do
      account = waha_account()

      ExWaha.ClientMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %{status: 401, headers: [], body: "nope"}}
      end)

      assert {:error, %ExWaha.Error{reason: :unauthorized, status: 401}} =
               Messages.send_text(account, "201001234567", "hi")
    end

    test "maps 429 to :rate_limited" do
      account = waha_account()

      ExWaha.ClientMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %{status: 429, headers: [], body: "slow down"}}
      end)

      assert {:error, %ExWaha.Error{reason: :rate_limited}} =
               Messages.send_text(account, "201001234567", "hi")
    end
  end

  describe "send_media/4" do
    test "dispatches to /api/sendImage for :image" do
      account = waha_account()

      ExWaha.ClientMock
      |> expect(:request, fn :post, url, _h, body, _o ->
        assert url =~ "/api/sendImage"
        assert body.chatId =~ "@c.us"
        assert body.session == "profile_test"
        {:ok, %{status: 201, headers: [], body: %{}}}
      end)

      assert {:ok, _} =
               Messages.send_media(account, "201001234567", %{
                 type: :image,
                 file: %{url: "https://example.com/img.png"}
               })
    end
  end
end
