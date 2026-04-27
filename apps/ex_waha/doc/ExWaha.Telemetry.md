# `ExWaha.Telemetry`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/telemetry.ex#L1)

Telemetry event names emitted by ex_waha.

Standard span events (`:start`, `:stop`, `:exception`) are emitted for every
outbound call. Subscribe via `:telemetry.attach/4`.

Events:

  * `[:ex_waha, :request, :start | :stop | :exception]`
  * `[:ex_waha, :webhook, :received]`
  * `[:ex_waha, :rate_limit, :throttled]`
  * `[:ex_waha, :session, :status_changed]`

# `emit`

```elixir
@spec emit([atom()], map(), map()) :: :ok
```

# `span`

```elixir
@spec span([atom()], map(), (-&gt; any())) :: any()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
