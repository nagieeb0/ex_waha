# Multi-tenancy

ExWaha owns no persistence and reads no application config inside the call
path. Every function takes an account struct as the first argument, which
makes it natively multi-tenant — but you have to model the mapping yourself.

## Two axes of tenancy

```
Tenant axis            ExWaha primitive            Where it lives
─────────────────────  ─────────────────────────  ────────────────────
Infrastructure         %ExWaha.Instance{}          your `instances` table
                       (base_url + api_key)
                       — one WAHA server

Account / business     session name                derived from profile_id
                       (string per WhatsApp #)
```

You may have a single shared WAHA server hosting many sessions (cheaper,
single point of failure) **or** one WAHA per tenant (isolation, costlier).
The same `%Account{}` shape supports both.

## Recommended schema

```elixir
defmodule MyApp.Repo.Migrations.CreateWhatsappTables do
  use Ecto.Migration

  def change do
    create table(:waha_instances, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false                 # "shared", "customer-acme"
      add :base_url, :string, null: false
      add :api_key, :string, null: false              # encrypted at rest
      add :webhook_secret, :string, null: false
      timestamps()
    end

    create table(:whatsapp_sessions) do
      add :profile_id, references(:profiles, type: :uuid), null: false
      add :instance_id, references(:waha_instances, type: :uuid), null: false
      add :session_name, :string, null: false         # "profile_<uuid_short>"
      add :status, :string, default: "stopped"        # mirrors WAHA's enum
      add :phone_number, :string
      add :paired_at, :utc_datetime
      add :last_status_at, :utc_datetime
      timestamps()
    end

    create unique_index(:whatsapp_sessions, [:instance_id, :session_name])
    create unique_index(:whatsapp_sessions, [:profile_id])
  end
end
```

## A context module that returns the right account

```elixir
defmodule MyApp.Whatsapp do
  alias ExWaha.{Instance, Providers.Waha.Account}
  alias MyApp.Repo

  def account_for!(profile_id) do
    session = Repo.get_by!(MyApp.Whatsapp.Session, profile_id: profile_id)
    instance = Repo.get!(MyApp.Whatsapp.Instance, session.instance_id)

    Account.new(
      Instance.new(base_url: instance.base_url, api_key: instance.api_key),
      session.session_name,
      webhook_secret: instance.webhook_secret
    )
  end
end
```

Every controller, LiveView, Oban worker, and Ash action that wants to send a
WhatsApp message goes through this single function. **Never derive the
account from URL params** — always from the *current authenticated user's*
profile, or you risk one tenant sending as another.

## Authorization rule of thumb

```elixir
defmodule MyAppWeb.WhatsappController do
  def send(conn, %{"text" => text, "to" => to}) do
    profile = conn.assigns.current_user.profile          # <-- from session
    account = MyApp.Whatsapp.account_for!(profile.id)    # <-- not from params

    case ExWaha.send_text(account, to, text) do
      {:ok, _} -> json(conn, %{ok: true})
      {:error, %ExWaha.Error{reason: r}} -> conn |> put_status(422) |> json(%{error: r})
    end
  end
end
```

## Routing webhooks back to a tenant

When WAHA fires a webhook, the URL must encode enough to look up the right
account. Two common patterns:

1. **Per-tenant URL path**: `/webhooks/waha/:profile_id` — `WebhookPlug`
   resolves the account from the path param.
2. **Per-instance + session in body**: `/webhooks/waha/:instance_id` —
   resolve to the right session using `payload["session"]`.

Pattern (1) is simpler if you have one WAHA serving everyone. Pattern (2)
fits when WAHA hosts many sessions per server.

```elixir
# pattern (1)
forward "/webhooks/waha/:profile_id",
        ExWahaPhoenix.WebhookPlug,
        handler: MyApp.Whatsapp.Handler,
        account: fn conn -> MyApp.Whatsapp.account_for!(conn.path_params["profile_id"]) end
```

## Bringing sessions under supervision at startup

If you want every active session running its safety GenServer immediately
after boot (instead of lazily on first send):

```elixir
defmodule MyApp.Whatsapp.Bootstrapper do
  use Task, restart: :transient

  def start_link(_), do: Task.start_link(__MODULE__, :run, [])

  def run do
    MyApp.Whatsapp.list_active_sessions()
    |> Enum.each(fn session ->
      account = MyApp.Whatsapp.account_for!(session.profile_id)
      {:ok, pid} = ExWaha.Session.Supervisor.ensure_started(account)
      ExWaha.Session.Server.set_status(pid, status_atom(session.status))
    end)
  end

  defp status_atom("WORKING"), do: :working
  defp status_atom(_), do: :stopped
end
```

Add `MyApp.Whatsapp.Bootstrapper` to your `Application` children, after the
Repo. Skip it if you'd rather have lazy registration on first call.
