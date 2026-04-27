# `ExWaha.Session.Server`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/session/server.ex#L1)

Per-account state machine.

Holds:

  * the account struct
  * status (`:stopped | :starting | :scan_qr | :working | :failed`)
  * a token-bucket rate limiter (sized by warmup age)
  * jitter config

`gated_call/2` is the public API used by `ExWaha.SafeSend`. It serializes the
rate-limit check (so two concurrent senders can't both consume the last
token) but releases the GenServer before performing the HTTP call so the
process is not the bottleneck.

# `status`

```elixir
@type status() :: :stopped | :starting | :scan_qr | :working | :failed
```

# `child_spec`

Returns a specification to start this module under a supervisor.

See `Supervisor`.

# `gated_call`

```elixir
@spec gated_call(pid() | GenServer.name(), (-&gt; any()), timeout()) :: any()
```

Block until rate limit allows, then run `fun` outside the GenServer.

# `set_status`

```elixir
@spec set_status(pid() | GenServer.name(), status()) :: :ok
```

# `start_link`

# `status`

```elixir
@spec status(pid() | GenServer.name()) :: status()
```

# `subscribe`

```elixir
@spec subscribe(pid() | GenServer.name(), pid()) :: :ok
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
