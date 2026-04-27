Here's the end-to-end setup for using it in a Phoenix project from GitHub.

  1. Add the deps

  In your Phoenix app's mix.exs, add whichever combination you need (point to the umbrella subpaths via sparse:):

  defp deps do
    [
      # ... your existing phoenix deps ...

      # Core (always needed)
      {:ex_waha, github: "nagieeb/ex_waha", sparse: "apps/ex_waha"},

      # Phoenix webhook plug (recommended)
      {:ex_waha_phoenix, github: "nagieeb/ex_waha", sparse: "apps/ex_waha_phoenix"},

      # Pick ONE message transport:
      # (a) Native — Go bridge, no Docker:
      {:ex_waha_native, github: "nagieeb/ex_waha", sparse: "apps/ex_waha_native"},
      # (b) Or run a WAHA Docker container and skip ex_waha_native entirely.
    ]
  end

  Then:

  mix deps.get

  2. Build the native bridge (only if using ex_waha_native)

  You need Go ≥ 1.21 on PATH:

  mix ex_waha_native.build_native
  # produces deps/ex_waha_native/priv/native/whatsmeow_bridge

  For production releases, run this on the build machine before mix release. To cross-compile:

  mix ex_waha_native.build_native --target linux/amd64

  3. Start the safety supervisor

  In lib/my_app/application.ex, add the safety GenServer tree to your children:

  def start(_type, _args) do
    children = [
      MyAppWeb.Telemetry,
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Endpoint,

      # ex_waha — rate-limit + warmup + jitter for outbound messages
      ExWaha.Session.Registry,
      ExWaha.Session.Supervisor

      # If using ex_waha_native, its own Application starts the
      # Bridge + Session.{Registry,Supervisor} for you. Nothing to add here.
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
  end

  4. A tenant module that resolves accounts

  lib/my_app/whatsapp.ex:

  defmodule MyApp.Whatsapp do
    @moduledoc "Resolves a per-profile WhatsApp account."

    alias MyApp.Accounts.Profile
    alias MyApp.Repo

    # WAHA-server flavour
    def account_for(%Profile{id: id, waha_secret: secret}) do
      instance =
        ExWaha.Instance.new(
          base_url: System.fetch_env!("WAHA_BASE_URL"),
          api_key: System.fetch_env!("WAHA_API_KEY")
        )

      ExWaha.Providers.Waha.Account.new(instance, "profile_#{id}", webhook_secret: secret)
    end

    # OR native flavour (no WAHA server)
    def native_account_for(%Profile{id: id}) do
      %ExWahaNative.Account{
        session: "profile_#{id}",
        store: {:sqlite, Path.join("priv/sessions", "#{id}.db")},
        bridge: ExWahaNative.Bridge
      }
    end

    # For the webhook plug
    def account_for_conn(%Plug.Conn{path_params: %{"profile_id" => pid}}) do
      Repo.get!(Profile, pid) |> account_for()
    end
  end

  5. Inbound webhooks (Phoenix)

  In lib/my_app_web/endpoint.ex, replace the default body reader so HMAC verification can see the raw body:

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {ExWahaPhoenix.WebhookPlug, :read_body, []}

  In lib/my_app_web/router.ex:

  scope "/" do
    forward "/webhooks/waha/:profile_id",
            ExWahaPhoenix.WebhookPlug,
            handler: MyAppWeb.WhatsappHandler,
            account: {MyApp.Whatsapp, :account_for_conn, []}
  end

  lib/my_app_web/whatsapp_handler.ex:

  defmodule MyAppWeb.WhatsappHandler do
    @behaviour ExWaha.Webhooks.Handler

    require Logger

    def handle_event(%{type: :message, from: from, body: body}, %{account: account}) do
      Logger.info("inbound: #{from} -> #{inspect(body)}")
      ExWaha.send_text(account, from, "echo: #{body}")
    end

    def handle_event(%{type: :message_ack, status: s, message_id: id}, _ctx) do
      Logger.info("ack #{s} #{id}")
    end

    def handle_event(_event, _ctx), do: :ok
  end

  Then point WAHA's webhook URL (or Meta's webhook URL in App Dashboard) at:
  https://yourapp.com/webhooks/waha/<profile_id>

  6. Outbound (from a controller / LiveView / Oban worker)

  def send_welcome(profile, phone) do
    account = MyApp.Whatsapp.account_for(profile)

    # Bring the safety GenServer up once per process restart
    {:ok, _pid} = ExWaha.Session.Supervisor.ensure_started(account)

    ExWaha.send_text(account, phone, "Welcome 👋")
  end

  For ex_waha_native, the first send_text will fail until the device is paired. Trigger pairing from a LiveView:

  def mount(%{"profile_id" => pid}, _session, socket) do
    account = MyApp.Whatsapp.native_account_for(%Profile{id: pid})
    {:ok, _} = ExWahaNative.Session.Supervisor.ensure_started(account)
    ExWahaNative.Session.subscribe(account)
    {:ok, assign(socket, account: account, qr: ExWahaNative.Session.qr(account))}
  end

  def handle_info({:ex_waha_native, :qr, %{"code" => code}}, socket) do
    {:noreply, assign(socket, qr: code)}        # render with a QR generator
  end

  def handle_info({:ex_waha_native, :paired, _}, socket) do
    {:noreply, assign(socket, qr: nil)}
  end

  Gotchas

  - Sparse deps need git refs that include the file at top of repo — if mix deps.get complains, pin a tag/commit: {:ex_waha, github: "nagieeb/ex_waha", sparse:
  "apps/ex_waha", ref: "v0.1.0"}.
  - Native binary must ship with your release. Add it to :files in your release config or use rel/overlays/ so Application.app_dir(:ex_waha_native,
  ["priv","native","whatsmeow_bridge"]) resolves at runtime.
  - WhatsApp ban risk — read apps/ex_waha/guides/safety_and_bans.md before sending volume from ex_waha_native or WAHA. The safety layer (token bucket + warmup +
  jitter) is on by default when you go through ExWaha.send_text/3; bypass it only if you know what you're doing.
