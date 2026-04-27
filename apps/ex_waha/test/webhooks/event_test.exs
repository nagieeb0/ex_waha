defmodule ExWaha.Webhooks.EventTest do
  use ExUnit.Case, async: true

  alias ExWaha.Webhooks.Event

  test "from_waha decodes a message event" do
    payload = %{
      "event" => "message",
      "session" => "profile_1",
      "timestamp" => 1_700_000_000,
      "payload" => %{
        "from" => "201001234567@c.us",
        "body" => "hi",
        "chatId" => "201001234567@c.us"
      }
    }

    event = Event.from_waha(payload)
    assert event.provider == :waha
    assert event.kind == :message
    assert event.session == "profile_1"
    assert event.body == "hi"
  end

  test "from_meta returns a list including statuses" do
    msg = %{"from" => "1444", "timestamp" => "1700000000", "text" => %{"body" => "yo"}}

    status = %{
      "recipient_id" => "1444",
      "status" => "delivered",
      "timestamp" => "1700000001"
    }

    payload = %{
      "entry" => [
        %{
          "changes" => [
            %{
              "value" => %{
                "metadata" => %{"display_phone_number" => "1555"},
                "messages" => [msg],
                "statuses" => [status]
              }
            }
          ]
        }
      ]
    }

    events = Event.from_meta(payload)
    assert length(events) == 2
    assert Enum.any?(events, &(&1.kind == :message and &1.body == "yo"))
    assert Enum.any?(events, &(&1.kind == :message_ack and &1.ack_status == "delivered"))
  end
end
