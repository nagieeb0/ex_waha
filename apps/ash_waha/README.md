# AshWaha

[![Hex.pm](https://img.shields.io/hexpm/v/ash_waha.svg)](https://hex.pm/packages/ash_waha)
[![Documentation](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ash_waha)

[Ash](https://ash-hq.org) extension for [`ex_waha`](https://hex.pm/packages/ex_waha).
Express WhatsApp behavior as resource DSL, with sends running inside Ash
actions — so policies, validations, audit, and AshOban background jobs all
just work.

> **Status: skeleton.** The DSL section and one functional change
> (`AshWaha.Changes.SendText`) ship in 0.1.0. The transformer that
> auto-injects standard actions onto resources is planned for 0.2.0. For
> now, declare custom actions and add the change explicitly.

## Installation

```elixir
def deps do
  [
    {:ash, "~> 3.4"},
    {:ex_waha, "~> 0.1.0"},
    {:ash_waha, "~> 0.1.0"}
  ]
end
```

## Quick example

```elixir
defmodule MyApp.Whatsapp.Profile do
  use Ash.Resource,
    domain: MyApp.Whatsapp,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshWaha]

  attributes do
    uuid_primary_key :id
    attribute :phone_number, :string, allow_nil?: false
  end

  whatsapp do
    account {MyApp.Whatsapp.Accounts, :for_profile, []}
  end

  actions do
    defaults [:read]

    update :send_welcome do
      argument :greeting, :string, default: "Welcome!"
      change AshWaha.Changes.SendText, text_arg: :greeting
    end

    update :send_otp do
      argument :code, :string, allow_nil?: false
      change AshWaha.Changes.SendText, text_arg: :code
    end
  end

  policies do
    policy action_type(:update) do
      authorize_if relates_to_actor_via(:owner)
    end
  end
end

# Wire up the account resolver
defmodule MyApp.Whatsapp.Accounts do
  alias ExWaha.{Instance, Providers.Waha.Account}

  def for_profile(%MyApp.Whatsapp.Profile{id: id}) do
    Account.new(
      Instance.new(base_url: System.fetch_env!("WAHA_URL"), api_key: System.fetch_env!("WAHA_KEY")),
      "profile_#{id}"
    )
  end
end

# Send a message — through Ash, with policy enforcement
profile
|> Ash.Changeset.for_update(:send_welcome, %{greeting: "Hi Mo!"}, actor: current_user)
|> Ash.update!()
```

## Why Ash

You get for free:

- **Authorization**: a policy that says "only the profile owner can send" is
  enforced before any HTTP call leaves your app.
- **Audit**: every send is an Ash action — log it, track it, report on it.
- **Validation**: changesets reject malformed phone numbers / empty text
  before billing time on Meta.
- **Background jobs**: pair with [AshOban](https://hexdocs.pm/ash_oban) and a
  `:send_welcome` action becomes an idempotent worker with retries.
- **GraphQL / JSON:API**: expose `:send_otp` as a mutation with
  [AshGraphql](https://hexdocs.pm/ash_graphql) — no extra controller.

## DSL reference

```elixir
whatsapp do
  account {MyModule, :function, [extra, args]}   # required
  session_name &MyModule.session_for/1            # optional
  on_event [{:message, MyApp.MessageHandler},     # optional, future use
            {:message_ack, MyApp.AckHandler}]
end
```

| Option | Type | Description |
|---|---|---|
| `account` | MFA / 1-arity function / struct | Returns the `%ExWaha.Providers.Waha.Account{}` (or Meta) for a record. |
| `session_name` | function / expression | Override the default session name derivation. |
| `on_event` | `[{kind, module}]` | Inbound webhook routing. |

See the full [DSL reference](guides/dsl_reference.md).

## Documentation

- [DSL reference](guides/dsl_reference.md)

## License

MIT. See the LICENSE file included in the package.
