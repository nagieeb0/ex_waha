# Send via Meta's WhatsApp Business Cloud API.
#
# Usage:
#   export META_PHONE_NUMBER_ID="..."
#   export META_ACCESS_TOKEN="..."
#   export META_RECIPIENT="+201001234567"
#   mix run examples/02_send_via_meta.exs

phone_number_id = System.fetch_env!("META_PHONE_NUMBER_ID")
token = System.fetch_env!("META_ACCESS_TOKEN")
recipient = System.fetch_env!("META_RECIPIENT")

account =
  ExWaha.Providers.Meta.Account.new(
    phone_number_id: phone_number_id,
    access_token: token,
    api_version: "v22.0"
  )

IO.puts("Sending free-form text (only valid inside the 24h window) -> #{recipient}")

case ExWaha.send_text(account, recipient, "Hello via Meta Cloud API") do
  {:ok, body} -> IO.inspect(body, label: "TEXT OK")
  {:error, err} -> IO.inspect(err, label: "TEXT ERROR")
end

IO.puts("\nSending an approved template (works outside the 24h window) -> #{recipient}")

case ExWaha.send_template(account, recipient, "hello_world", language: "en_US") do
  {:ok, body} -> IO.inspect(body, label: "TEMPLATE OK")
  {:error, err} -> IO.inspect(err, label: "TEMPLATE ERROR")
end
