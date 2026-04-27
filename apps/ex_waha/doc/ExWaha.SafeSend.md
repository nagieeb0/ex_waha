# `ExWaha.SafeSend`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/safety/safe_send.ex#L1)

The single gate every outbound message must pass through.

Responsibilities:

  1. Locate (or skip) the per-account `ExWaha.Session.Server`.
  2. Check the rate-limit token bucket.
  3. Verify the session is in a sendable state.
  4. Apply randomized jitter (ban-risk mitigation).
  5. Emit telemetry on throttle and dispatch.

If no session server is registered for the account (e.g. tests, or an app
that hasn't started one), `dispatch/2` falls through to the inner function
without limits — explicit opt-in to safety via the OTP layer.

# `result`

```elixir
@type result() :: {:ok, any()} | {:error, ExWaha.Error.t()}
```

# `dispatch`

```elixir
@spec dispatch(
  struct(),
  (-&gt; result())
) :: result()
```

# `sleep_jitter`

```elixir
@spec sleep_jitter(non_neg_integer()) :: :ok
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
