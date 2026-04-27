defmodule ExWahaPhoenix.WebhookPlug do
  @moduledoc """
  Plug that receives webhook POSTs from WAHA or Meta, verifies the HMAC
  signature, parses the payload into normalized events, and dispatches them
  to the host application's handler module.

  ## Mounting

      forward "/webhooks/waha/:account_id",
              ExWahaPhoenix.WebhookPlug,
              handler: MyAppWeb.WahaHandler,
              account: {MyApp.Whatsapp, :account_for, []}

  The `:account` option is an MFA called with `[conn]` to resolve the account
  struct (so you can route by URL param to the right tenant).

  ## Raw body

  Signature verification needs the *raw* request body. Add this to your
  endpoint's parsers:

      plug Plug.Parsers,
        parsers: [:urlencoded, :json],
        json_decoder: Jason,
        body_reader: {ExWahaPhoenix.WebhookPlug, :read_body, []}
  """

  @behaviour Plug

  import Plug.Conn

  alias ExWaha.{Provider, Webhooks.Handler}

  @impl true
  def init(opts) do
    %{
      handler: Keyword.fetch!(opts, :handler),
      account: Keyword.fetch!(opts, :account),
      context: Keyword.get(opts, :context, %{})
    }
  end

  @impl true
  def call(conn, %{handler: handler, account: account_resolver, context: context}) do
    account = resolve_account(account_resolver, conn)

    with {:ok, body, conn} <- read_cached_body(conn),
         true <- verify_signature(account, body, conn.req_headers),
         {:ok, payload} <- Jason.decode(body),
         {:ok, events} <- Provider.provider_for!(account).parse_event(account, payload) do
      Handler.dispatch(handler, events, Map.merge(context, %{account: account, conn: conn}))
      send_resp(conn, 200, "ok")
    else
      false ->
        send_resp(conn, 401, "invalid signature")

      {:error, %Jason.DecodeError{}} ->
        send_resp(conn, 400, "invalid json")

      _other ->
        send_resp(conn, 400, "bad request")
    end
  end

  @doc """
  Body reader to plug into `Plug.Parsers` so the raw body remains available
  for HMAC verification after JSON parsing.
  """
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        conn = put_private(conn, :ex_waha_raw_body, body)
        {:ok, body, conn}

      {:more, body, conn} ->
        prev = conn.private[:ex_waha_raw_body] || ""
        conn = put_private(conn, :ex_waha_raw_body, prev <> body)
        {:more, body, conn}

      other ->
        other
    end
  end

  defp read_cached_body(conn) do
    case conn.private[:ex_waha_raw_body] do
      nil ->
        Plug.Conn.read_body(conn, length: 8_000_000)

      body ->
        {:ok, body, conn}
    end
  end

  defp verify_signature(account, body, headers) do
    Provider.provider_for!(account).verify_signature(account, body, headers)
  end

  defp resolve_account({m, f, a}, conn), do: apply(m, f, [conn | a])
  defp resolve_account(fun, conn) when is_function(fun, 1), do: fun.(conn)
  defp resolve_account(%_{} = account, _conn), do: account
end
