# `ExWahaNative.Bridge`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.2.0/lib/ex_waha_native/bridge.ex#L1)

GenServer that owns the Go bridge `Port` and routes traffic between
Elixir callers and the whatsmeow process.

  * Outbound: serializes `%{op, args}` requests to length-prefixed JSON,
    stores `ref -> from` for the reply.
  * Inbound: stream-decodes frames; routes `response` to the awaiting
    caller, dispatches `event` to the session GenServer.

## Crash semantics

If the Port closes (Go process died), this GenServer exits. Its supervisor
restarts it, which re-spawns the Go binary. whatsmeow re-connects every
session from sqlstore. In-flight requests get `{:error, :bridge_restart}`.

# `call`

```elixir
@spec call(GenServer.name(), String.t(), String.t(), map(), timeout()) ::
  {:ok, any()} | {:error, term()}
```

Synchronously send a request to the Go bridge and await its response.

# `cast`

```elixir
@spec cast(GenServer.name(), String.t(), String.t(), map()) :: :ok
```

Fire-and-forget op.

# `child_spec`

Returns a specification to start this module under a supervisor.

See `Supervisor`.

# `start_link`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
