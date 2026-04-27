defmodule ExWaha.Webhooks.Handler do
  @moduledoc """
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
  """

  alias ExWaha.{Telemetry, Webhooks.Event}

  @type context :: map()
  @callback handle_event(Event.t(), context()) :: :ok | {:error, term()}

  @doc "Run the handler for each event with telemetry around it."
  @spec dispatch(module(), [Event.t()] | Event.t(), context()) :: :ok
  def dispatch(handler, events, context) when is_list(events) do
    Enum.each(events, &dispatch(handler, &1, context))
  end

  def dispatch(handler, %Event{} = event, context) do
    Telemetry.emit([:webhook, :received], %{}, %{kind: event.kind, provider: event.provider})

    try do
      handler.handle_event(event, context)
    rescue
      e -> {:error, e}
    end

    :ok
  end
end
