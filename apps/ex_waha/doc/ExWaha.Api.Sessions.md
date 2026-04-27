# `ExWaha.Api.Sessions`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/api/sessions.ex#L1)

WAHA `/api/sessions` endpoints.

WAHA sessions follow this lifecycle:

    STOPPED ──start──▶ STARTING ──pair──▶ SCAN_QR ──scan──▶ WORKING
                                                            │
                                                            └─▶ FAILED

All functions take an `ExWaha.Providers.Waha.Account` (which carries the
session name) and return `{:ok, body} | {:error, %ExWaha.Error{}}`.

# `create`

```elixir
@spec create(ExWaha.Providers.Waha.Account.t(), map()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

Create the session on WAHA. Idempotent — safe to call repeatedly.

Pass `config` to set webhooks, proxy, debug flags, etc. (see WAHA docs).

## Example

    ExWaha.Api.Sessions.create(account, %{
      webhooks: [
        %{
          url: "https://api.example.com/webhooks/waha/profile_42",
          events: ["message", "session.status"],
          hmac: %{key: account.webhook_secret}
        }
      ]
    })

# `get`

```elixir
@spec get(ExWaha.Providers.Waha.Account.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

Fetch the current session by name (from the account).

# `list`

```elixir
@spec list(ExWaha.Providers.Waha.Account.t()) ::
  {:ok, [map()]} | {:error, ExWaha.Error.t()}
```

List all sessions on the WAHA server.

## Example

    {:ok, sessions} = ExWaha.Api.Sessions.list(account)
    Enum.map(sessions, & &1["name"])
    #=> ["profile_42", "profile_99"]

# `logout`

```elixir
@spec logout(ExWaha.Providers.Waha.Account.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

Log out and unpair the WhatsApp account. Requires re-scanning a QR.

# `restart`

```elixir
@spec restart(ExWaha.Providers.Waha.Account.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

Stop then start the session — sometimes needed after long idle periods.

# `start`

```elixir
@spec start(ExWaha.Providers.Waha.Account.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

Start a previously-created (and stopped) session.

# `stop`

```elixir
@spec stop(ExWaha.Providers.Waha.Account.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

Stop the session (preserves the WhatsApp pairing).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
