defmodule ExWaha.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nagieeb/ex_waha"

  def project do
    [
      app: :ex_waha,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "ExWaha",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {ExWaha.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.2"},
      {:plug, "~> 1.16", optional: true},
      {:mox, "~> 1.1", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    "WhatsApp client for Elixir — supports WAHA (self-hosted) and Meta Cloud API."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "WAHA" => "https://waha.devlike.pro"
      },
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md guides .formatter.exs)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "guides/getting_started.md",
        "guides/multi_tenancy.md",
        "guides/safety_and_bans.md",
        "guides/webhooks.md",
        "guides/providers.md",
        "guides/telemetry.md"
      ],
      groups_for_extras: [
        Guides: ~r/guides\/.*/
      ],
      groups_for_modules: [
        "Public API": [ExWaha, ExWaha.SafeSend],
        "Provider — WAHA": [
          ExWaha.Providers.Waha,
          ExWaha.Providers.Waha.Account,
          ExWaha.Instance
        ],
        "Provider — Meta": [
          ExWaha.Providers.Meta,
          ExWaha.Providers.Meta.Account
        ],
        "WAHA REST API": [
          ExWaha.Api.Sessions,
          ExWaha.Api.Auth,
          ExWaha.Api.Messages,
          ExWaha.Api.Chats,
          ExWaha.Api.Contacts,
          ExWaha.Api.Groups,
          ExWaha.Api.Presence,
          ExWaha.Api.Profile
        ],
        "OTP & Safety": [
          ExWaha.Session.Server,
          ExWaha.Session.Supervisor,
          ExWaha.Session.Registry,
          ExWaha.Safety.RateLimiter,
          ExWaha.Safety.Warmup
        ],
        Webhooks: [
          ExWaha.Webhooks.Event,
          ExWaha.Webhooks.Signature,
          ExWaha.Webhooks.Handler
        ],
        Behaviours: [ExWaha.Provider, ExWaha.Client],
        Internals: [
          ExWaha.Client.Req,
          ExWaha.Error,
          ExWaha.Recipient,
          ExWaha.Telemetry
        ]
      ]
    ]
  end
end
