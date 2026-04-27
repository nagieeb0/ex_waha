defmodule ExWahaPhoenix.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nagieeb/ex_waha"

  def project do
    [
      app: :ex_waha_phoenix,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Phoenix adapter for ex_waha — webhook plug and dashboard.",
      package: package(),
      docs: docs(),
      name: "ExWahaPhoenix",
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_waha, in_umbrella: true},
      {:plug, "~> 1.16"},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
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
        "guides/webhooks.md",
        "guides/dashboard.md"
      ]
    ]
  end
end
