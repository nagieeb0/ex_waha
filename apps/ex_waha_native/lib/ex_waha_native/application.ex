defmodule ExWahaNative.Application do
  @moduledoc false

  use Application

  alias ExWaha.Provider

  @impl true
  def start(_type, _args) do
    Provider.register(ExWahaNative.Account, ExWahaNative.Provider)

    children =
      [
        {Registry, keys: :unique, name: ExWahaNative.Session.Registry},
        ExWahaNative.Session.Supervisor
      ] ++ maybe_bridge()

    Supervisor.start_link(children, strategy: :one_for_one, name: ExWahaNative.Supervisor)
  end

  defp maybe_bridge do
    if Application.get_env(:ex_waha_native, :start_bridge, false) do
      [{ExWahaNative.Bridge, name: ExWahaNative.Bridge}]
    else
      []
    end
  end
end
