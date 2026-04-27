defmodule ExWaha.Client do
  @moduledoc """
  HTTP client behaviour. Implementations: `ExWaha.Client.Req` (default) and
  `ExWaha.ClientMock` (test only).

  Designed so all transport concerns are a single mockable seam.
  """

  alias ExWaha.Error

  @type method :: :get | :post | :put | :patch | :delete
  @type url :: String.t()
  @type headers :: [{String.t(), String.t()}]
  @type body :: nil | binary() | map() | list()
  @type opts :: keyword()
  @type response :: {:ok, %{status: non_neg_integer(), headers: headers(), body: any()}}
  @type error :: {:error, Error.t()}

  @callback request(method(), url(), headers(), body(), opts()) :: response() | error()

  @spec impl() :: module()
  def impl do
    Application.get_env(:ex_waha, :default_client, ExWaha.Client.Req)
  end

  @spec request(method(), url(), headers(), body(), opts()) :: response() | error()
  def request(method, url, headers, body, opts) do
    impl().request(method, url, headers, body, opts)
  end
end
