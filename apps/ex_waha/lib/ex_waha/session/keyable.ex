defprotocol ExWaha.Session.Keyable do
  @moduledoc """
  Maps an account struct to the term used as its `Session.Server` registry key.

  Implementations live next to each account struct. External provider apps
  (e.g. `:ex_waha_native`) implement this for their own account modules
  rather than the core registry growing a clause per provider — that would
  invert the dependency graph (core depending on extensions).
  """

  @spec key(term()) :: term()
  def key(account)
end

defimpl ExWaha.Session.Keyable, for: ExWaha.Providers.Waha.Account do
  def key(%{instance: %{base_url: url}, session: session}), do: {:waha, url, session}
end

defimpl ExWaha.Session.Keyable, for: ExWaha.Providers.Meta.Account do
  def key(%{phone_number_id: pn_id}), do: {:meta, pn_id}
end
