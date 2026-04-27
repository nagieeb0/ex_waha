defmodule ExWaha.Recipient do
  @moduledoc """
  Normalized recipient handle.

  Different providers expect different chat-id formats. This struct captures the
  canonical phone number plus an optional WAHA-style chat id, and provides
  helpers to render the right shape per provider.

  WAHA expects `<digits>@c.us` for users and `<id>@g.us` for groups. Meta Cloud
  API expects E.164 digits without `+`.
  """

  @enforce_keys [:phone]
  defstruct [:phone, :chat_id, type: :user]

  @type t :: %__MODULE__{
          phone: String.t(),
          chat_id: nil | String.t(),
          type: :user | :group
        }

  @doc """
  Build a user `Recipient` from a phone string. Non-digits are stripped.

      iex> ExWaha.Recipient.new("+20 (100) 123-4567")
      %ExWaha.Recipient{phone: "201001234567", chat_id: "201001234567@c.us", type: :user}

  Already-built `Recipient` structs pass through unchanged.
  """
  @spec new(String.t() | t()) :: t()
  def new(%__MODULE__{} = r), do: r

  def new(phone) when is_binary(phone) do
    digits = sanitize(phone)
    %__MODULE__{phone: digits, chat_id: "#{digits}@c.us", type: :user}
  end

  @doc """
  Build a group `Recipient` from a WAHA group id.

      iex> ExWaha.Recipient.group("123-456")
      %ExWaha.Recipient{phone: "123-456", chat_id: "123-456@g.us", type: :group}
  """
  @spec group(String.t()) :: t()
  def group(group_id) when is_binary(group_id) do
    %__MODULE__{phone: group_id, chat_id: "#{group_id}@g.us", type: :group}
  end

  @doc "Render the recipient in WAHA's `<id>@c.us` / `<id>@g.us` format."
  @spec to_waha(t()) :: String.t()
  def to_waha(%__MODULE__{chat_id: chat_id}) when is_binary(chat_id), do: chat_id
  def to_waha(%__MODULE__{phone: p, type: :user}), do: "#{sanitize(p)}@c.us"
  def to_waha(%__MODULE__{phone: p, type: :group}), do: "#{p}@g.us"

  @doc "Render the recipient as plain digits for the Meta Cloud API."
  @spec to_meta(t()) :: String.t()
  def to_meta(%__MODULE__{phone: p}), do: sanitize(p)

  defp sanitize(phone) do
    phone
    |> String.replace(~r/[^\d]/, "")
  end
end
