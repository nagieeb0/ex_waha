# `ExWaha.Api.Auth`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/api/auth.ex#L1)

Pairing endpoints — QR scan and SMS code request.

WhatsApp authentication happens once per session. Render the QR (or
request a numeric code) to the user, who confirms in the WhatsApp mobile
app under *Linked Devices*.

After a successful pairing, WAHA fires a `session.status` webhook with
status `WORKING`. Update your `ExWaha.Session.Server` accordingly.

# `qr`

```elixir
@spec qr(
  ExWaha.Providers.Waha.Account.t(),
  keyword()
) :: {:ok, any()} | {:error, ExWaha.Error.t()}
```

Fetch the QR code for the session.

## Options

  * `:format` — `:raw` (default) or `:image`
    - `:raw` returns `{:ok, %{"value" => "<base64>"}}`
    - `:image` returns the raw PNG bytes (caller decodes)

## Example (LiveView)

    def handle_info(:poll_qr, socket) do
      case ExWaha.Api.Auth.qr(socket.assigns.account, format: :raw) do
        {:ok, %{"value" => b64}} ->
          {:noreply, assign(socket, qr: b64)}

        {:error, _} ->
          Process.send_after(self(), :poll_qr, 2000)
          {:noreply, socket}
      end
    end

# `request_code`

```elixir
@spec request_code(ExWaha.Providers.Waha.Account.t(), String.t()) ::
  {:ok, map()} | {:error, ExWaha.Error.t()}
```

Request a numeric pairing code (alternative to QR scanning).

Useful when the user can't easily scan a screen — they enter the returned
code in WhatsApp → Linked Devices → Link with phone number instead.

    ExWaha.Api.Auth.request_code(account, "+201001234567")
    #=> {:ok, %{"code" => "ABC1-DEF2"}}

# `screenshot`

```elixir
@spec screenshot(ExWaha.Providers.Waha.Account.t()) ::
  {:ok, any()} | {:error, ExWaha.Error.t()}
```

Take a screenshot of the WhatsApp Web view (debug aid).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
