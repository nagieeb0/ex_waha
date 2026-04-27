# `ExWaha.Session.Supervisor`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/session/supervisor.ex#L1)

DynamicSupervisor for per-account `ExWaha.Session.Server` processes.

# `child_spec`

Returns a specification to start this module under a supervisor.

See `Supervisor`.

# `ensure_started`

```elixir
@spec ensure_started(struct(), keyword()) :: {:ok, pid()} | {:error, term()}
```

Start (or look up) the session server for an account. Idempotent.

# `start_link`

# `stop`

```elixir
@spec stop(struct()) :: :ok | {:error, :not_found}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
