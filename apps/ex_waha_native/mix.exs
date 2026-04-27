defmodule ExWahaNative.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/nagieeb/ex_waha"

  def project do
    [
      app: :ex_waha_native,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "ExWahaNative",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExWahaNative.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_waha, in_umbrella: true},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Native Elixir <-> Go (whatsmeow) bridge for ex_waha — no WAHA Docker required."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "whatsmeow" => "https://github.com/tulir/whatsmeow"
      },
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md native priv .formatter.exs)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
