defmodule ExWaha.Provider do
  @moduledoc """
  Behaviour every WhatsApp provider implements.

  Built-in providers (`ExWaha.Providers.Waha`, `ExWaha.Providers.Meta`)
  register themselves at application start. External provider packages
  (e.g. `:ex_waha_native`) register their account-struct → provider mapping
  via `register/2` from their own `Application.start/2`.
  """

  alias ExWaha.{Error, Recipient, Webhooks}

  @type account :: struct()
  @type recipient :: Recipient.t() | String.t()
  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @callback send_text(account(), recipient(), String.t(), keyword()) :: result(map())
  @callback send_media(account(), recipient(), map(), keyword()) :: result(map())
  @callback send_template(account(), recipient(), String.t(), keyword()) :: result(map())
  @callback verify_signature(account(), binary(), [{String.t(), String.t()}]) :: boolean()
  @callback parse_event(account(), map()) :: {:ok, [Webhooks.Event.t()]} | {:error, term()}

  @optional_callbacks [send_template: 4, send_media: 4, verify_signature: 3, parse_event: 2]

  @registry_key {__MODULE__, :registry}

  @doc """
  Register a provider implementation for an account-struct module.

  Idempotent. Overwrites any previous registration.
  """
  @spec register(module(), module()) :: :ok
  def register(account_module, provider_module)
      when is_atom(account_module) and is_atom(provider_module) do
    current = :persistent_term.get(@registry_key, %{})
    :persistent_term.put(@registry_key, Map.put(current, account_module, provider_module))
  end

  @doc "Look up the provider module for an account struct."
  @spec provider_for!(account()) :: module()
  def provider_for!(%mod{} = _account) do
    case Map.fetch(:persistent_term.get(@registry_key, %{}), mod) do
      {:ok, provider} -> provider
      :error -> raise ArgumentError, "no provider registered for #{inspect(mod)}"
    end
  end

  @spec send_text(account(), recipient(), String.t(), keyword()) :: result(map())
  def send_text(account, recipient, text, opts) do
    provider_for!(account).send_text(account, normalize(recipient), text, opts)
  end

  @spec send_media(account(), recipient(), map(), keyword()) :: result(map())
  def send_media(account, recipient, media, opts) do
    provider_for!(account).send_media(account, normalize(recipient), media, opts)
  end

  @spec send_template(account(), recipient(), String.t(), keyword()) :: result(map())
  def send_template(account, recipient, template, opts) do
    provider_for!(account).send_template(account, normalize(recipient), template, opts)
  end

  defp normalize(%Recipient{} = r), do: r
  defp normalize(phone) when is_binary(phone), do: Recipient.new(phone)
end
