defmodule ExWaha.Client.Req do
  @moduledoc """
  Default `ExWaha.Client` implementation backed by `Req`.

  Returns `{:ok, response}` on any HTTP response (caller maps status to error)
  and `{:error, %ExWaha.Error{}}` on transport failures.
  """

  @behaviour ExWaha.Client

  alias ExWaha.Error

  @impl true
  def request(method, url, headers, body, opts) do
    req_opts =
      [
        method: method,
        url: url,
        headers: headers,
        receive_timeout: Keyword.get(opts, :receive_timeout_ms, 30_000),
        connect_options: [timeout: Keyword.get(opts, :timeout_ms, 10_000)]
      ]
      |> maybe_put_body(body)

    case Req.request(req_opts) do
      {:ok, %Req.Response{} = resp} ->
        {:ok, %{status: resp.status, headers: resp.headers, body: resp.body}}

      {:error, %{__exception__: true} = exc} ->
        {:error,
         Error.exception(
           reason: :network,
           message: Exception.message(exc),
           body: exc
         )}
    end
  end

  defp maybe_put_body(opts, nil), do: opts
  defp maybe_put_body(opts, body) when is_binary(body), do: Keyword.put(opts, :body, body)
  defp maybe_put_body(opts, body), do: Keyword.put(opts, :json, body)
end
