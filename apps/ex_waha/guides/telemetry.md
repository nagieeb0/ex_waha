# Telemetry events

Every outbound HTTP call is wrapped in a `:telemetry.span/3`, plus discrete
events for rate-limit decisions and session status changes.

## Subscribing

```elixir
:telemetry.attach_many(
  "ex-waha",
  [
    [:ex_waha, :request, :start],
    [:ex_waha, :request, :stop],
    [:ex_waha, :request, :exception],
    [:ex_waha, :rate_limit, :throttled],
    [:ex_waha, :rate_limit, :jitter],
    [:ex_waha, :session, :status_changed],
    [:ex_waha, :webhook, :received]
  ],
  &MyApp.Telemetry.handle/4,
  nil
)
```

## Event reference

### `[:ex_waha, :request, :start]` / `:stop` / `:exception`

Standard `:telemetry.span` events around every provider HTTP call.

**Measurements** (on `:stop`):
- `:duration` (native time units)

**Metadata**:
- `:provider` — `:waha` or `:meta`
- `:method` — HTTP verb (WAHA only)
- `:path` — URL path (WAHA only)
- `:op` — `:send_text \| :send_media \| :send_template \| :send_location \| ...`
- `:ok?` (on `:stop`) — `true` if the call returned `{:ok, _}`

### `[:ex_waha, :rate_limit, :throttled]`

Emitted when `Session.Server.gated_call/2` refuses a call because the token
bucket is empty.

**Measurements**: `%{wait_ms: integer}` — how long until a token is
expected to be available.
**Metadata**: `%{}`

### `[:ex_waha, :rate_limit, :jitter]`

Emitted when `SafeSend.sleep_jitter/1` pauses before dispatching the
underlying call.

**Measurements**: `%{ms: integer}`
**Metadata**: `%{}`

### `[:ex_waha, :session, :status_changed]`

Emitted by `Session.Server` when the session's status atom changes.

**Measurements**: `%{}`
**Metadata**:
- `:from` — previous status atom
- `:to` — new status atom
- `:account` — registry key tuple (e.g. `{:waha, base_url, session}`)

### `[:ex_waha, :webhook, :received]`

Emitted by `Webhooks.Handler.dispatch/3` for each event before invoking the
host handler.

**Measurements**: `%{}`
**Metadata**:
- `:kind` — `Event.kind`
- `:provider` — `:waha \| :meta`

## Example: prom_ex / Logger integration

```elixir
defmodule MyApp.Telemetry do
  require Logger

  def handle([:ex_waha, :request, :stop], %{duration: dur}, %{op: op, ok?: ok?}, _) do
    Logger.info("ex_waha #{op} #{ok? && "ok" || "err"} #{System.convert_time_unit(dur, :native, :millisecond)}ms")
  end

  def handle([:ex_waha, :rate_limit, :throttled], %{wait_ms: ms}, _, _) do
    Logger.warning("ex_waha rate limited — backoff #{ms}ms")
  end

  def handle([:ex_waha, :session, :status_changed], _, %{from: from, to: to, account: acct}, _) do
    Logger.info("ex_waha #{inspect(acct)} #{from} -> #{to}")
  end

  def handle(_, _, _, _), do: :ok
end
```
