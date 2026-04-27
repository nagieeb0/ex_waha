# `ExWahaNative.Wire`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.2.0/lib/ex_waha_native/wire.ex#L1)

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

# `frame`

```elixir
@type frame() :: binary()
```

# `message`

```elixir
@type message() :: map()
```

# `decode_stream`

```elixir
@spec decode_stream(binary(), [message()]) :: {[message()], binary()}
```

Stream-decode bytes from the Port.

Returns `{messages, leftover}` — call again with the leftover prepended to
the next chunk.

# `encode!`

```elixir
@spec encode!(message()) :: frame()
```

# `new_ref`

```elixir
@spec new_ref() :: String.t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
