defmodule ExWaha.Api.Sessions do
  @moduledoc """
  WAHA `/api/sessions` endpoints.

  WAHA sessions follow this lifecycle:

      STOPPED ──start──▶ STARTING ──pair──▶ SCAN_QR ──scan──▶ WORKING
                                                              │
                                                              └─▶ FAILED

  All functions take an `ExWaha.Providers.Waha.Account` (which carries the
  session name) and return `{:ok, body} | {:error, %ExWaha.Error{}}`.
  """

  import ExWaha.Api.Helpers

  alias ExWaha.Providers.Waha.Account

  @doc """
  List all sessions on the WAHA server.

  ## Example

      {:ok, sessions} = ExWaha.Api.Sessions.list(account)
      Enum.map(sessions, & &1["name"])
      #=> ["profile_42", "profile_99"]
  """
  @spec list(Account.t()) :: {:ok, [map()]} | {:error, ExWaha.Error.t()}
  def list(%Account{instance: inst}) do
    request(inst, :get, "/api/sessions", nil)
  end

  @doc "Fetch the current session by name (from the account)."
  @spec get(Account.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def get(%Account{instance: inst, session: s}) do
    request(inst, :get, "/api/sessions/" <> s, nil)
  end

  @doc """
  Create the session on WAHA. Idempotent — safe to call repeatedly.

  Pass `config` to set webhooks, proxy, debug flags, etc. (see WAHA docs).

  ## Example

      ExWaha.Api.Sessions.create(account, %{
        webhooks: [
          %{
            url: "https://api.example.com/webhooks/waha/profile_42",
            events: ["message", "session.status"],
            hmac: %{key: account.webhook_secret}
          }
        ]
      })
  """
  @spec create(Account.t(), map()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def create(%Account{instance: inst, session: s}, config \\ %{}) do
    body = %{name: s, start: true, config: config}
    request(inst, :post, "/api/sessions", body)
  end

  @doc "Start a previously-created (and stopped) session."
  @spec start(Account.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def start(%Account{instance: inst, session: s}) do
    request(inst, :post, "/api/sessions/" <> s <> "/start", %{})
  end

  @doc "Stop the session (preserves the WhatsApp pairing)."
  @spec stop(Account.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def stop(%Account{instance: inst, session: s}) do
    request(inst, :post, "/api/sessions/" <> s <> "/stop", %{})
  end

  @doc "Log out and unpair the WhatsApp account. Requires re-scanning a QR."
  @spec logout(Account.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def logout(%Account{instance: inst, session: s}) do
    request(inst, :post, "/api/sessions/" <> s <> "/logout", %{})
  end

  @doc "Stop then start the session — sometimes needed after long idle periods."
  @spec restart(Account.t()) :: {:ok, map()} | {:error, ExWaha.Error.t()}
  def restart(%Account{instance: inst, session: s}) do
    request(inst, :post, "/api/sessions/" <> s <> "/restart", %{})
  end
end
