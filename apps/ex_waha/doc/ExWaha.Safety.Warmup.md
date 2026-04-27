# `ExWaha.Safety.Warmup`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/safety/warmup.ex#L1)

Account warmup curve.

WhatsApp's anti-spam systems are most aggressive against new numbers and
numbers that suddenly start sending more. A new account should send slowly
and ramp up over days. This module computes the bucket parameters for a
given account age.

# `bucket_params`

```elixir
@type bucket_params() :: {pos_integer(), float()}
```

Bucket parameters: {capacity, refill_per_second}.

# `params`

```elixir
@spec params(
  integer(),
  keyword()
) :: bucket_params()
```

# `random_jitter_ms`

```elixir
@spec random_jitter_ms(keyword()) :: non_neg_integer()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
