defmodule ExWaha.Providers.Meta.Account do
  @moduledoc """
  An account on Meta's WhatsApp Business Cloud API.
  """

  @enforce_keys [:phone_number_id, :access_token]
  defstruct [
    :phone_number_id,
    :access_token,
    :app_secret,
    :business_account_id,
    api_base: "https://graph.facebook.com",
    api_version: "v22.0"
  ]

  @type t :: %__MODULE__{
          phone_number_id: String.t(),
          access_token: String.t(),
          app_secret: nil | String.t(),
          business_account_id: nil | String.t(),
          api_base: String.t(),
          api_version: String.t()
        }

  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts), do: struct!(__MODULE__, opts)
end
