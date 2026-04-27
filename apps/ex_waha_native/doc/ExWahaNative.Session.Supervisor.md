# `ExWahaNative.Session.Supervisor`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.2.0/lib/ex_waha_native/session/supervisor.ex#L1)

DynamicSupervisor for per-account `ExWahaNative.Session` processes.

# `child_spec`

Returns a specification to start this module under a supervisor.

See `Supervisor`.

# `ensure_started`

```elixir
@spec ensure_started(
  ExWahaNative.Account.t(),
  keyword()
) :: {:ok, pid()} | {:error, term()}
```

# `start_link`

# `stop`

```elixir
@spec stop(ExWahaNative.Account.t()) :: :ok | {:error, :not_found}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
