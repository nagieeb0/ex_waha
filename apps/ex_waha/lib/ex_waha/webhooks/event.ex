defmodule ExWaha.Webhooks.Event do
  @moduledoc """
  Normalized webhook event.

  WAHA and Meta send wildly different payloads — this struct is the lowest
  common denominator that downstream code (handlers, LiveViews, Oban jobs)
  works with. The raw provider payload is preserved for advanced cases.
  """

  @type kind ::
          :message
          | :message_ack
          | :message_reaction
          | :session_status
          | :group_update
          | :presence
          | :unknown

  @enforce_keys [:provider, :kind, :raw]
  defstruct [
    :provider,
    :kind,
    :session,
    :timestamp,
    :from,
    :to,
    :chat_id,
    :body,
    :media,
    :ack_status,
    :raw
  ]

  @type t :: %__MODULE__{
          provider: :waha | :meta,
          kind: kind(),
          session: nil | String.t(),
          timestamp: nil | DateTime.t(),
          from: nil | String.t(),
          to: nil | String.t(),
          chat_id: nil | String.t(),
          body: nil | String.t(),
          media: nil | map(),
          ack_status: nil | atom(),
          raw: map()
        }

  ## WAHA -> Event

  @spec from_waha(map()) :: t()
  def from_waha(%{"event" => event} = payload) do
    %__MODULE__{
      provider: :waha,
      kind: waha_kind(event),
      session: payload["session"],
      timestamp: parse_ts(payload["timestamp"]),
      from: get_in(payload, ["payload", "from"]),
      to: get_in(payload, ["payload", "to"]),
      chat_id: get_in(payload, ["payload", "chatId"]),
      body: get_in(payload, ["payload", "body"]),
      ack_status: get_in(payload, ["payload", "ack"]),
      raw: payload
    }
  end

  def from_waha(payload) when is_map(payload) do
    %__MODULE__{provider: :waha, kind: :unknown, raw: payload}
  end

  defp waha_kind("message"), do: :message
  defp waha_kind("message.ack"), do: :message_ack
  defp waha_kind("message.reaction"), do: :message_reaction
  defp waha_kind("session.status"), do: :session_status
  defp waha_kind("group.v2." <> _), do: :group_update
  defp waha_kind("presence.update"), do: :presence
  defp waha_kind(_), do: :unknown

  ## Meta -> Event(s)

  @spec from_meta(map()) :: [t()]
  def from_meta(%{"entry" => entries}) when is_list(entries) do
    Enum.flat_map(entries, &meta_entry_to_events/1)
  end

  def from_meta(payload) when is_map(payload) do
    [%__MODULE__{provider: :meta, kind: :unknown, raw: payload}]
  end

  defp meta_entry_to_events(%{"changes" => changes}) when is_list(changes) do
    Enum.flat_map(changes, fn change ->
      value = Map.get(change, "value", %{})
      meta_messages(value) ++ meta_statuses(value)
    end)
  end

  defp meta_entry_to_events(_), do: []

  defp meta_messages(%{"messages" => msgs} = value) when is_list(msgs) do
    metadata = Map.get(value, "metadata", %{})

    Enum.map(msgs, fn msg ->
      %__MODULE__{
        provider: :meta,
        kind: :message,
        timestamp: parse_ts(msg["timestamp"]),
        from: msg["from"],
        to: metadata["display_phone_number"],
        body: get_in(msg, ["text", "body"]),
        raw: msg
      }
    end)
  end

  defp meta_messages(_), do: []

  defp meta_statuses(%{"statuses" => statuses}) when is_list(statuses) do
    Enum.map(statuses, fn status ->
      %__MODULE__{
        provider: :meta,
        kind: :message_ack,
        timestamp: parse_ts(status["timestamp"]),
        to: status["recipient_id"],
        ack_status: status["status"],
        raw: status
      }
    end)
  end

  defp meta_statuses(_), do: []

  defp parse_ts(nil), do: nil

  defp parse_ts(ts) when is_integer(ts) do
    DateTime.from_unix!(ts)
  end

  defp parse_ts(ts) when is_binary(ts) do
    case Integer.parse(ts) do
      {n, ""} -> DateTime.from_unix!(n)
      _ -> nil
    end
  end
end
