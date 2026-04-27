defmodule ExWahaUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp deps, do: []

  defp aliases do
    [
      check: ["compile --warnings-as-errors", "format --check-formatted", "test"]
    ]
  end
end
