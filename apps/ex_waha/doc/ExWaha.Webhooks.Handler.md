# `ExWaha.Webhooks.Handler`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/webhooks/handler.ex#L1)

Behaviour host applications implement to receive normalized events.

Mount the host's handler module via `ExWahaPhoenix.WebhookPlug` (Phoenix
apps) or call `ExWaha.Webhooks.Handler.dispatch/3` directly from a custom
transport.

## Example

    defmodule MyApp.WhatsappHandler do
      @behaviour ExWaha.Webhooks.Handler

      def handle_event(%ExWaha.Webhooks.Event{kind: :message} = event, ctx) do
        MyApp.Whatsapp.persist_inbound(event, ctx)
        :ok
      end

      def handle_event(_event, _ctx), do: :ok
    end

# `context`

```elixir
@type context() :: map()
```

# `handle_event`

```elixir
@callback handle_event(ExWaha.Webhooks.Event.t(), context()) :: :ok | {:error, term()}
```

# `dispatch`

```elixir
@spec dispatch(
  module(),
  [ExWaha.Webhooks.Event.t()] | ExWaha.Webhooks.Event.t(),
  context()
) :: :ok
```

Run the handler for each event with telemetry around it.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
