defmodule AshWaha.Changes.SendText do
  @moduledoc """
  Ash change that sends a WhatsApp text message as part of an action.

  ## Options

    * `:text` — literal string to send.
    * `:text_arg` — name of an action argument whose value is the text.
    * `:recipient_attr` — name of the resource attribute holding the phone
      number. Defaults to `:phone_number`.
    * `:account` — overrides the resource-level `whatsapp.account` config.

  Usage:

      update :send_welcome do
        argument :greeting, :string, default: "Welcome!"
        change AshWaha.Changes.SendText, text_arg: :greeting
      end
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, opts, context) do
    Ash.Changeset.before_action(changeset, fn cs ->
      case dispatch(cs, opts, context) do
        {:ok, _} -> cs
        {:error, %ExWaha.Error{} = err} -> Ash.Changeset.add_error(cs, message: err.message)
      end
    end)
  end

  defp dispatch(changeset, opts, _context) do
    text = resolve_text(changeset, opts)
    recipient = resolve_recipient(changeset, opts)
    account = resolve_account(changeset, opts)

    ExWaha.send_text(account, recipient, text)
  end

  defp resolve_text(changeset, opts) do
    cond do
      text = opts[:text] -> text
      arg = opts[:text_arg] -> Ash.Changeset.get_argument(changeset, arg)
      true -> raise ArgumentError, "AshWaha.Changes.SendText requires :text or :text_arg"
    end
  end

  defp resolve_recipient(changeset, opts) do
    attr = Keyword.get(opts, :recipient_attr, :phone_number)
    Map.fetch!(changeset.data, attr)
  end

  defp resolve_account(changeset, opts) do
    case Keyword.get(opts, :account) do
      nil -> resource_account(changeset)
      {m, f, a} -> apply(m, f, [changeset.data | a])
      fun when is_function(fun, 1) -> fun.(changeset.data)
      %_{} = account -> account
    end
  end

  defp resource_account(changeset) do
    config = Spark.Dsl.Extension.get_opt(changeset.resource, [:whatsapp], :account)

    case config do
      {m, f, a} -> apply(m, f, [changeset.data | a])
      fun when is_function(fun, 1) -> fun.(changeset.data)
      %_{} = account -> account
      nil -> raise "no whatsapp.account configured on #{inspect(changeset.resource)}"
    end
  end
end
