defmodule ExWahaNative.Wire do
  @moduledoc """
  Length-prefixed JSON framing for the Bridge ↔ Go process protocol.

  Frame format on the wire:

      <<length::big-unsigned-integer-32, payload::binary>>

  Payloads are JSON. Three message kinds:

  ### Request (Elixir → Go)

      %{
        "type" => "request",
        "ref"  => "<uuid>",
        "session" => "profile_42",
        "op"   => "send_text",
        "args" => %{...}
      }

  ### Response (Go → Elixir, correlated by ref)

      %{
        "type" => "response",
        "ref"  => "<uuid>",
        "ok"   => true,
        "result" => %{...}
      }

      %{
        "type" => "response",
        "ref"  => "<uuid>",
        "ok"   => false,
        "error" => "...",
        "code"  => "..."
      }

  ### Event (Go → Elixir, no ref, server-initiated)

      %{
        "type" => "event",
        "session" => "profile_42",
        "kind"    => "message" | "qr" | "paired" | "disconnected" | ...,
        "payload" => %{...}
      }
  """

  @type frame :: binary()
  @type message :: map()

  @spec encode!(message()) :: frame()
  def encode!(message) when is_map(message) do
    json = Jason.encode!(message)
    <<byte_size(json)::big-unsigned-integer-32, json::binary>>
  end

  @doc """
  Stream-decode bytes from the Port.

  Returns `{messages, leftover}` — call again with the leftover prepended to
  the next chunk.
  """
  @spec decode_stream(binary(), [message()]) :: {[message()], binary()}
  def decode_stream(buffer, acc \\ [])

  def decode_stream(<<len::big-unsigned-integer-32, rest::binary>> = buffer, acc) do
    if byte_size(rest) >= len do
      <<payload::binary-size(len), tail::binary>> = rest

      case Jason.decode(payload) do
        {:ok, message} -> decode_stream(tail, [message | acc])
        {:error, _} -> {Enum.reverse(acc), buffer}
      end
    else
      {Enum.reverse(acc), buffer}
    end
  end

  def decode_stream(buffer, acc), do: {Enum.reverse(acc), buffer}

  @spec new_ref() :: String.t()
  def new_ref do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
