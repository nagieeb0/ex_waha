# `ExWaha.Api.Contacts`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/api/contacts.ex#L1)

WAHA contact endpoints. Use `check_exists/2` BEFORE sending to unknowns.

# `check_exists`

```elixir
@spec check_exists(ExWaha.Providers.Waha.Account.t(), String.t()) ::
  {:ok, %{exists: boolean(), chat_id: String.t() | nil}}
  | {:error, ExWaha.Error.t()}
```

Check whether a phone number is registered on WhatsApp.

This is the single most important call to make before sending unsolicited
outbound — sending to non-WhatsApp numbers is a strong ban signal.

# `get`

```elixir
@spec get(ExWaha.Providers.Waha.Account.t(), ExWaha.Recipient.t() | String.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

# `profile_picture`

```elixir
@spec profile_picture(
  ExWaha.Providers.Waha.Account.t(),
  ExWaha.Recipient.t() | String.t()
) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
