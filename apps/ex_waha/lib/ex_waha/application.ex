defmodule ExWaha.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    register_built_in_providers()

    children = [
      {Registry, keys: :unique, name: ExWaha.Session.Registry},
      ExWaha.Session.Supervisor
    ]

    opts = [strategy: :one_for_one, name: ExWaha.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp register_built_in_providers do
    ExWaha.Provider.register(ExWaha.Providers.Waha.Account, ExWaha.Providers.Waha)
    ExWaha.Provider.register(ExWaha.Providers.Meta.Account, ExWaha.Providers.Meta)
  end
end
