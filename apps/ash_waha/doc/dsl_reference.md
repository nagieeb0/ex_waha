# DSL reference

`AshWaha` adds one DSL section (`whatsapp`) and one Ash change
(`AshWaha.Changes.SendText`) to your resources.

## The `whatsapp` block

```elixir
defmodule MyApp.Whatsapp.Profile do
  use Ash.Resource,
    domain: MyApp.Whatsapp,
    extensions: [AshWaha]

  whatsapp do
    account {MyApp.Whatsapp.Accounts, :for_profile, []}
    session_name fn record -> "profile_#{record.id}" end
    on_event [
      {:message,     MyApp.Whatsapp.InboundHandler},
      {:message_ack, MyApp.Whatsapp.AckHandler}
    ]
  end
end
```

### `account` (required)

How to derive the `%ExWaha.Providers.Waha.Account{}` (or Meta account) for
a record. Three accepted shapes:

| Shape | Called as | When to use |
|---|---|---|
| MFA `{module, fun, args}` | `apply(module, fun, [record \| args])` | Default — keep your account-building logic in a real module |
| 1-arity function `&fn/1` | `fun.(record)` | Inline cases |
| Static struct `%Account{}` | returned as-is | Single global account |

```elixir
defmodule MyApp.Whatsapp.Accounts do
  alias ExWaha.{Instance, Providers.Waha.Account}

  def for_profile(%MyApp.Whatsapp.Profile{tenant_id: tenant_id, id: id}) do
    instance = MyApp.Whatsapp.instance_for_tenant!(tenant_id)

    Account.new(
      Instance.new(base_url: instance.base_url, api_key: instance.api_key),
      "profile_#{id}",
      webhook_secret: instance.webhook_secret
    )
  end
end
```

### `session_name` (optional)

Override the default session name. By default `account` already encodes the
session, so this option is rarely needed — useful only if you want the
extension's auto-generated actions (planned 0.2.0) to derive the session
differently from the explicit `account` lookup.

### `on_event` (optional, future)

List of `{kind, handler_module}` tuples for inbound webhook routing. Not
yet wired up; declared so you can register intent now.

## `AshWaha.Changes.SendText`

An Ash change that calls `ExWaha.send_text/4` inside an action. Run it as
a `before_action` so authorization policies and validations have already
fired.

```elixir
update :send_welcome do
  argument :greeting, :string, default: "Welcome!"
  change AshWaha.Changes.SendText, text_arg: :greeting
end
```

### Options

| Option | Type | Default | Description |
|---|---|---|---|
| `:text` | `String.t()` | — | Literal text to send. Mutually exclusive with `:text_arg`. |
| `:text_arg` | atom | — | Action argument name whose value becomes the text. |
| `:recipient_attr` | atom | `:phone_number` | Resource attribute holding the recipient phone. |
| `:account` | MFA / fun / struct | resource-level | Override the resource-level `whatsapp.account`. |

If neither `:text` nor `:text_arg` is provided, the change raises at
runtime.

### Behavior on send failure

`{:error, %ExWaha.Error{}}` from the underlying call is added to the
changeset as a regular Ash error, so the action returns `{:error, _}` and
the transaction (if any) rolls back.

```elixir
case Ash.update(profile, :send_welcome, %{greeting: "hi"}, actor: user) do
  {:ok, _} -> :sent
  {:error, %Ash.Error.Invalid{errors: [%{message: msg}]}} -> {:error, msg}
end
```

### Pairing with AshOban

```elixir
update :send_welcome do
  argument :greeting, :string, default: "Welcome!"
  change AshWaha.Changes.SendText, text_arg: :greeting
end

oban do
  triggers do
    trigger :send_welcome do
      action :send_welcome
      worker_module_name MyApp.Whatsapp.Workers.SendWelcome
      max_attempts 5
      queue :whatsapp
    end
  end
end
```

Now sending becomes idempotent and retried by Oban — and rate-limited by
ExWaha's token bucket as it leaves the worker.

## Roadmap

- **0.2.0** — Transformer that auto-injects standard actions
  (`:start_session`, `:request_qr`, `:status`, `:send_image`, etc.) onto
  any resource that uses the extension.
- **0.3.0** — Inbound `on_event` routing wired into `WebhookPlug`.
- **0.4.0** — AshGraphql / AshJsonApi auto-exposure of WhatsApp actions.
