defmodule ExWaha.RecipientTest do
  use ExUnit.Case, async: true

  alias ExWaha.Recipient

  test "strips non-digits from phone numbers" do
    r = Recipient.new("+20 (100) 123-4567")
    assert r.phone == "201001234567"
    assert r.chat_id == "201001234567@c.us"
  end

  test "to_waha for groups" do
    r = Recipient.group("123-456")
    assert Recipient.to_waha(r) == "123-456@g.us"
  end

  test "to_meta returns just digits" do
    r = Recipient.new("+20 100 123 4567")
    assert Recipient.to_meta(r) == "201001234567"
  end
end
