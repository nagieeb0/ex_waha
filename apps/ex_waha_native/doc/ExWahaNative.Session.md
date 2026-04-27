# `ExWahaNative.Session`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.2.0/lib/ex_waha_native/session.ex#L1)

Per-WhatsApp-account state machine.

Holds the account, current status, and a set of subscribers (LiveViews,
PubSub bridges, custom handlers) that get `{:ex_waha_native, kind, payload}`
messages on every event from the Go bridge for this session.

Outbound calls are routed through `ExWahaNative.Bridge`; this GenServer
doesn't serialize them — the Bridge does.

# `status`

```elixir
@type status() :: :stopped | :starting | :scan_qr | :working | :failed
```

# `child_spec`

Returns a specification to start this module under a supervisor.

See `Supervisor`.

# `logout`

```elixir
@spec logout(String.t() | ExWahaNative.Account.t()) :: :ok | {:error, term()}
```

Log the device out at the protocol level — wipes the paired session on
the WhatsApp servers and clears local state. After this the next `start`
triggers a fresh QR/pairing flow.

# `qr`

```elixir
@spec qr(String.t() | ExWahaNative.Account.t()) :: String.t() | nil
```

Returns the most recent QR code seen for the session, or `nil` if none.

When the account is unpaired, the bridge emits successive `qr` events as
the underlying WhatsApp QR rotates every ~20s. This helper exposes the
latest one so a controller/LiveView can render it without subscribing.

# `request_pairing_code`

```elixir
@spec request_pairing_code(String.t() | ExWahaNative.Account.t(), String.t()) ::
  {:ok, String.t()} | {:error, term()}
```

Request a phone-pairing code instead of QR.

WhatsApp 2.24+ supports linking a device via a numeric pairing code shown
on the phone. Returns `{:ok, code}` (formatted as e.g. `"ABCD-EFGH"`) or
an `{:error, reason}` if the session is not in a state to pair.

# `start_link`

# `status`

```elixir
@spec status(String.t() | ExWahaNative.Account.t()) :: status()
```

# `stop`

```elixir
@spec stop(String.t() | ExWahaNative.Account.t()) :: :ok
```

Stop the session GenServer (closes the device locally but does not
invalidate the WhatsApp pairing — `start` will reconnect).

# `subscribe`

```elixir
@spec subscribe(String.t() | ExWahaNative.Account.t(), pid()) :: :ok
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
