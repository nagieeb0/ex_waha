# Safety and bans

WhatsApp aggressively bans accounts that look automated. This is *not*
optional reading — getting banned at scale is the single biggest risk of
running on WAHA, and most defenses must be present *before* the first
message goes out. Meta's official Cloud API is friendlier but enforces
templates and the 24-hour customer service window instead.

## What gets you banned

| Signal | Risk | Mitigation built in |
|---|---|---|
| Bursty sends from a new number | **Very high** | Warmup curve in `Safety.Warmup` |
| Sending faster than a human types | High | Token bucket + jitter |
| Sending to non-WhatsApp numbers | High | `Api.Contacts.check_exists/2` before send |
| Recipient reports as spam | High | App-level: opt-in tracking, allow unsubscribe |
| Same number on multiple "devices" simultaneously | Medium | One WAHA session per number; don't share |
| Identical message body to many recipients | Medium | App-level: vary content, use templates on Meta |
| Sending outside business hours / time zones | Low–Medium | App-level: schedule sends respecting recipient TZ |

## What `:ex_waha` does for you

Every send routed through `ExWaha.send_text/4` (or `send_media`,
`send_template`) goes through `ExWaha.SafeSend.dispatch/2`, which:

1. Looks up the account's `Session.Server` in the registry.
2. Calls `gated_call/2` which serializes a token-bucket reservation.
3. If no token is available, returns `{:error, %Error{reason: :rate_limited, retry_after_ms: n}}`.
4. If the session isn't `:working`, returns `{:error, %Error{reason: :session_not_started}}`.
5. Otherwise sleeps a randomized jitter (default 300–1500ms) before
   making the HTTP call.

If no `Session.Server` is registered for the account, `dispatch/2` falls
through to the bare HTTP call — **explicit opt-out for tests and scripts**.
In production code paths, always run sessions under
`ExWaha.Session.Supervisor`.

## The warmup curve

`ExWaha.Safety.Warmup.params/2` interpolates the bucket size and refill
rate from "warmup" defaults to "steady-state" defaults over `:warmup_days`
days (default 14):

| Day | Capacity | Refill (msg/s) | Effective steady throughput |
|---|---|---|---|
| 0 | 5 | 0.2 | ~12 msg/min |
| 7 | 18 | 0.6 | ~36 msg/min |
| 14+ | 30 | 1.0 | ~60 msg/min |

These are **conservative** defaults intended to avoid bans on personal
WhatsApp numbers. Business API numbers tolerate more; tune with:

```elixir
# config/runtime.exs
config :ex_waha, :rate_limit,
  capacity: 60,
  refill_per_second: 2.0,
  warmup_days: 7,
  warmup_capacity: 10,
  warmup_refill_per_second: 0.5,
  jitter_ms: {500, 2500}
```

These are read once when each `Session.Server` initializes. To change the
bucket on a running session, restart it (terminate + ensure_started).

## Number existence checks

Sending to a number that isn't on WhatsApp is one of the strongest ban
signals. For any unsolicited outbound:

```elixir
case ExWaha.Api.Contacts.check_exists(account, phone) do
  {:ok, %{exists: true, chat_id: chat_id}} ->
    ExWaha.send_text(account, chat_id, text)

  {:ok, %{exists: false}} ->
    {:error, :not_on_whatsapp}

  {:error, _} = err ->
    err
end
```

Build this into your enqueue path so the check happens once per recipient
per day (cache it), not on every message.

## Things ExWaha cannot do for you

- **Consent tracking.** Persist explicit opt-in; reject sends to recipients
  who haven't opted in. Honor "STOP" replies.
- **Business hours.** Don't ping customers at 3am their local time.
- **Content variation.** Send 1000 identical messages and you will get
  banned regardless of rate limit.
- **Quiet days.** Long pauses then bursts look unnatural; spread sends out.
- **Recovery from ban.** If a session fails repeatedly, *stop sending from
  that account*. Continued sends after a ban accelerate further action.

## Detecting trouble

Monitor these telemetry events:

```elixir
:telemetry.attach_many(
  "ex-waha-bans",
  [
    [:ex_waha, :rate_limit, :throttled],
    [:ex_waha, :session, :status_changed],
    [:ex_waha, :request, :stop]
  ],
  &MyApp.WhatsappAlerts.handle/4,
  nil
)
```

Specifically alert on:
- `request.stop` with `error.reason in [:account_banned, :forbidden]`
- `session.status_changed` to `:failed` (especially if it bounces repeatedly)
- A spike in `rate_limit.throttled` (your senders are racing the bucket;
  raise capacity or reduce send pressure upstream)

When in doubt, **stop sending and investigate**. There is no "unblock"
button at WhatsApp.
