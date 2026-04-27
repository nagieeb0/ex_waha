# Send a text + image through a self-hosted WAHA server.
#
# Usage:
#   export WAHA_BASE_URL="http://localhost:3000"
#   export WAHA_API_KEY="your-api-key"
#   export WAHA_RECIPIENT="+201001234567"
#   mix run examples/01_send_via_waha.exs
#
# Assumes the WAHA server already has a started session called "default".

base_url = System.fetch_env!("WAHA_BASE_URL")
api_key = System.fetch_env!("WAHA_API_KEY")
recipient = System.fetch_env!("WAHA_RECIPIENT")

instance =
  ExWaha.Instance.new(
    base_url: base_url,
    api_key: api_key,
    timeout: 15_000
  )

account = ExWaha.Providers.Waha.Account.new(instance, "default")

IO.puts("Sending text -> #{recipient}")

case ExWaha.send_text(account, recipient, "Hello from ex_waha 👋") do
  {:ok, body} -> IO.inspect(body, label: "TEXT OK")
  {:error, err} -> IO.inspect(err, label: "TEXT ERROR")
end

IO.puts("\nSending image -> #{recipient}")

image = %{
  type: :image,
  file: %{url: "https://placehold.co/600x400.png"},
  caption: "via ex_waha + WAHA"
}

case ExWaha.send_media(account, recipient, image) do
  {:ok, body} -> IO.inspect(body, label: "IMAGE OK")
  {:error, err} -> IO.inspect(err, label: "IMAGE ERROR")
end
