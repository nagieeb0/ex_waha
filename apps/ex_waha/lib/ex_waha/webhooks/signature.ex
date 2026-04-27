defmodule ExWaha.Webhooks.Signature do
  @moduledoc """
  HMAC signature verification for webhook payloads.

    * WAHA — `HMAC-SHA512(body, secret)` hex digest in the `X-Webhook-Hmac` header.
    * Meta — `sha256=` + `HMAC-SHA256(body, app_secret)` hex digest in the
      `X-Hub-Signature-256` header.

  Constant-time comparison via `:crypto.hash_equals/2` to prevent timing
  attacks. Raw request body must be preserved (Plug strips it by default —
  use a `body_reader` to capture).
  """

  @spec verify_sha512(binary(), nil | String.t(), String.t()) :: boolean()
  def verify_sha512(_body, nil, _secret), do: false
  def verify_sha512(_body, _sig, nil), do: false

  def verify_sha512(body, sig, secret) when is_binary(body) and is_binary(sig) do
    expected = :crypto.mac(:hmac, :sha512, secret, body) |> Base.encode16(case: :lower)
    secure_equals?(String.downcase(sig), expected)
  end

  @spec verify_meta_sha256(binary(), nil | String.t(), String.t()) :: boolean()
  def verify_meta_sha256(_body, nil, _secret), do: false
  def verify_meta_sha256(_body, _sig, nil), do: false

  def verify_meta_sha256(body, "sha256=" <> hex, secret) when is_binary(body) do
    expected = :crypto.mac(:hmac, :sha256, secret, body) |> Base.encode16(case: :lower)
    secure_equals?(String.downcase(hex), expected)
  end

  def verify_meta_sha256(_body, _sig, _secret), do: false

  defp secure_equals?(a, b) when byte_size(a) == byte_size(b) do
    :crypto.hash_equals(a, b)
  end

  defp secure_equals?(_, _), do: false
end
