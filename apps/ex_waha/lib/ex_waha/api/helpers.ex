defmodule ExWaha.Api.Helpers do
  @moduledoc false

  alias ExWaha.{Client, Error, Instance, Telemetry}

  @spec request(Instance.t(), atom(), String.t(), any(), map()) ::
          {:ok, any()} | {:error, Error.t()}
  def request(%Instance{} = inst, method, path, body, telemetry_meta \\ %{}) do
    url = String.trim_trailing(inst.base_url, "/") <> path
    headers = headers(inst)

    opts = [
      timeout_ms: inst.timeout_ms,
      receive_timeout_ms: inst.receive_timeout_ms
    ]

    Telemetry.span(
      [:request],
      Map.merge(%{provider: :waha, method: method, path: path}, telemetry_meta),
      fn ->
        case Client.request(method, url, headers, body, opts) do
          {:ok, %{status: s, body: b}} when s in 200..299 -> {:ok, b}
          {:ok, %{status: s, body: b}} -> {:error, Error.from_status(s, b)}
          {:error, %Error{}} = err -> err
        end
      end
    )
  end

  defp headers(%Instance{api_key: nil} = inst) do
    base_headers(inst)
  end

  defp headers(%Instance{api_key: key} = inst) do
    [{"x-api-key", key} | base_headers(inst)]
  end

  defp base_headers(%Instance{headers: extra}) do
    [{"content-type", "application/json"}, {"accept", "application/json"} | extra]
  end
end
