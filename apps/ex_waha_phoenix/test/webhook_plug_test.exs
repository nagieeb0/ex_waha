defmodule ExWahaPhoenix.WebhookPlugTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  import Plug.Test

  alias ExWaha.{Instance, Providers.Waha.Account}
  alias ExWahaPhoenix.WebhookPlug

  defmodule TestHandler do
    @behaviour ExWaha.Webhooks.Handler
    def handle_event(event, _ctx) do
      send(self(), {:got, event})
      :ok
    end
  end

  defp account do
    Account.new(
      Instance.new(base_url: "http://waha.test"),
      "profile_test",
      webhook_secret: "shhh"
    )
  end

  defp opts(account_resolver \\ &__MODULE__.fixed_account/1) do
    WebhookPlug.init(handler: TestHandler, account: account_resolver)
  end

  def fixed_account(_conn), do: account()

  test "rejects bad signature" do
    body = ~s({"event":"message","session":"profile_test","payload":{"body":"hi"}})

    conn =
      conn(:post, "/", body)
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-webhook-hmac", "deadbeef")

    conn = WebhookPlug.call(conn, opts())
    assert conn.status == 401
  end

  test "accepts a valid signature and dispatches" do
    body = ~s({"event":"message","session":"profile_test","payload":{"body":"hi"}})
    sig = :crypto.mac(:hmac, :sha512, "shhh", body) |> Base.encode16(case: :lower)

    conn =
      conn(:post, "/", body)
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-webhook-hmac", sig)

    conn = WebhookPlug.call(conn, opts())
    assert conn.status == 200
  end
end
