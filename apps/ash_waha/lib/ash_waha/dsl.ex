defmodule AshWaha.Dsl do
  @moduledoc """
  Spark DSL definition for the `whatsapp` block on Ash resources.
  """

  @account_doc "MFA or 1-arity fun returning the ExWaha account struct."
  @session_doc "Function or expression returning the WAHA session name."
  @event_doc "List of `{kind, handler_module}` tuples for inbound dispatch."

  @whatsapp %Spark.Dsl.Section{
    name: :whatsapp,
    describe: "Configure WhatsApp messaging for this resource.",
    schema: [
      account: [type: :any, required: true, doc: @account_doc],
      session_name: [type: :any, doc: @session_doc],
      on_event: [type: {:list, :any}, default: [], doc: @event_doc]
    ]
  }

  @doc false
  def whatsapp_section, do: @whatsapp
end
