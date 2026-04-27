defmodule ExWahaNative.WireTest do
  use ExUnit.Case, async: true

  alias ExWahaNative.Wire

  describe "encode!/1" do
    test "produces a length-prefixed frame" do
      frame = Wire.encode!(%{type: "request", op: "ping"})
      <<len::big-unsigned-integer-32, payload::binary>> = frame
      assert byte_size(payload) == len
      assert Jason.decode!(payload) == %{"type" => "request", "op" => "ping"}
    end
  end

  describe "decode_stream/2" do
    test "decodes a single complete frame" do
      msg = %{type: "response", ref: "abc", ok: true}
      frame = Wire.encode!(msg)
      assert {[decoded], <<>>} = Wire.decode_stream(frame)
      assert decoded == %{"type" => "response", "ref" => "abc", "ok" => true}
    end

    test "decodes multiple back-to-back frames" do
      f1 = Wire.encode!(%{n: 1})
      f2 = Wire.encode!(%{n: 2})
      f3 = Wire.encode!(%{n: 3})
      assert {decoded, <<>>} = Wire.decode_stream(f1 <> f2 <> f3)
      assert Enum.map(decoded, & &1["n"]) == [1, 2, 3]
    end

    test "returns leftover bytes when payload is incomplete" do
      frame = Wire.encode!(%{n: 1})
      <<half::binary-size(byte_size(frame) - 5), _rest::binary>> = frame
      assert {[], leftover} = Wire.decode_stream(half)
      assert leftover == half
    end

    test "returns leftover bytes when length header is incomplete" do
      assert {[], <<1, 2>>} = Wire.decode_stream(<<1, 2>>)
    end

    test "round-trip after split chunks" do
      msg = %{type: "event", session: "s1", kind: "message", payload: %{"body" => "hi"}}
      frame = Wire.encode!(msg)
      mid = div(byte_size(frame), 2)
      <<chunk_a::binary-size(mid), chunk_b::binary>> = frame

      {[], leftover} = Wire.decode_stream(chunk_a)
      assert {[decoded], <<>>} = Wire.decode_stream(leftover <> chunk_b)
      assert decoded["payload"] == %{"body" => "hi"}
    end
  end

  describe "new_ref/0" do
    test "produces unique URL-safe tokens" do
      a = Wire.new_ref()
      b = Wire.new_ref()
      assert byte_size(a) > 0
      assert a != b
      assert a =~ ~r/\A[A-Za-z0-9_-]+\z/
    end
  end
end
