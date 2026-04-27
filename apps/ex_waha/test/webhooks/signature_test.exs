defmodule ExWaha.Webhooks.SignatureTest do
  use ExUnit.Case, async: true

  alias ExWaha.Webhooks.Signature

  describe "verify_sha512/3 (WAHA)" do
    test "accepts a valid signature" do
      secret = "shhh"
      body = ~s({"event":"message"})
      sig = :crypto.mac(:hmac, :sha512, secret, body) |> Base.encode16(case: :lower)
      assert Signature.verify_sha512(body, sig, secret)
    end

    test "rejects a tampered body" do
      secret = "shhh"
      body = ~s({"event":"message"})
      sig = :crypto.mac(:hmac, :sha512, secret, body) |> Base.encode16(case: :lower)
      refute Signature.verify_sha512(body <> "x", sig, secret)
    end

    test "rejects nil signature" do
      refute Signature.verify_sha512("body", nil, "secret")
    end
  end

  describe "verify_meta_sha256/3" do
    test "accepts the sha256= prefixed signature" do
      secret = "app_secret"
      body = ~s({"object":"whatsapp_business_account"})
      hex = :crypto.mac(:hmac, :sha256, secret, body) |> Base.encode16(case: :lower)
      assert Signature.verify_meta_sha256(body, "sha256=" <> hex, secret)
    end

    test "rejects unprefixed signatures" do
      secret = "s"
      body = "x"
      hex = :crypto.mac(:hmac, :sha256, secret, body) |> Base.encode16(case: :lower)
      refute Signature.verify_meta_sha256(body, hex, secret)
    end
  end
end
