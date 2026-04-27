# `ExWaha.Providers.Waha.Account`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/providers/waha/account.ex#L1)

An account on a specific WAHA server.

Combines:

  * `instance` — `%ExWaha.Instance{}` (server connection details)
  * `session` — WAHA session name, typically derived from your tenant id
    (e.g. `"profile_42"`)
  * `webhook_secret` — optional HMAC-SHA512 secret WAHA was configured with

# `t`

```elixir
@type t() :: %ExWaha.Providers.Waha.Account{
  instance: ExWaha.Instance.t(),
  session: String.t(),
  webhook_secret: nil | String.t()
}
```

# `new`

```elixir
@spec new(ExWaha.Instance.t(), String.t(), keyword()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
