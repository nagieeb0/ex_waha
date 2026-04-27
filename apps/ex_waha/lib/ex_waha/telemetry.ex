defmodule ExWaha.Telemetry do
  @moduledoc """
  Telemetry event names emitted by ex_waha.

  Standard span events (`:start`, `:stop`, `:exception`) are emitted for every
  outbound call. Subscribe via `:telemetry.attach/4`.

  Events:

    * `[:ex_waha, :request, :start | :stop | :exception]`
    * `[:ex_waha, :webhook, :received]`
    * `[:ex_waha, :rate_limit, :throttled]`
    * `[:ex_waha, :session, :status_changed]`
  """

  @spec span(list(atom()), map(), (-> any())) :: any()
  def span(name_segments, metadata, fun) do
    :telemetry.span([:ex_waha | name_segments], metadata, fn ->
      result = fun.()
      {result, Map.put(metadata, :ok?, match?({:ok, _}, result))}
    end)
  end

  @spec emit(list(atom()), map(), map()) :: :ok
  def emit(name_segments, measurements, metadata) do
    :telemetry.execute([:ex_waha | name_segments], measurements, metadata)
  end
end
