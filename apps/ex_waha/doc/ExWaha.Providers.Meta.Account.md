# `ExWaha.Providers.Meta.Account`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/providers/meta/account.ex#L1)

An account on Meta's WhatsApp Business Cloud API.

# `t`

```elixir
@type t() :: %ExWaha.Providers.Meta.Account{
  access_token: String.t(),
  api_base: String.t(),
  api_version: String.t(),
  app_secret: nil | String.t(),
  business_account_id: nil | String.t(),
  phone_number_id: String.t()
}
```

# `new`

```elixir
@spec new(keyword()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
