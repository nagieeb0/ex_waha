defmodule ExWaha do
  @moduledoc """
  Public facade for the ex_waha library.

  ExWaha is a provider-agnostic WhatsApp client. Two providers ship in the box:

    * `ExWaha.Providers.Waha` — wraps a self-hosted WAHA server (WhatsApp HTTP API).
    * `ExWaha.Providers.Meta` — wraps Meta's official WhatsApp Business Cloud API.

  Both implement `ExWaha.Provider`. Application code talks to the facade and
  the facade dispatches based on the account struct it receives.

  ## Multi-tenancy

  ExWaha is stateless and persistence-free. Each call takes an account struct
  (`ExWaha.Providers.Waha.Account` or `ExWaha.Providers.Meta.Account`) and a
  recipient. Host applications own the mapping `profile_id -> account` in their
  database. See the [Multi-tenancy guide](multi_tenancy.md).

  ## Ban risk

  WhatsApp aggressively bans accounts that look like bots. The OTP layer
  (`ExWaha.Session.Server`) enforces a token-bucket rate limit, a warmup ramp
  for new sessions, and randomized jitter between sends. Outbound code paths
  should go through this facade (which calls `ExWaha.SafeSend`) rather than
  the raw provider modules. See the [Safety and bans guide](safety_and_bans.md).

  ## Quick examples

      account =
        ExWaha.Providers.Waha.Account.new(
          ExWaha.Instance.new(base_url: "http://localhost:3000", api_key: "key"),
          "profile_42"
        )

      ExWaha.send_text(account, "+201001234567", "Hello!")
      #=> {:ok, %{"id" => "msg_abc"}}
  """

  alias ExWaha.{Provider, SafeSend}

  @typedoc "Either a WAHA or Meta account struct."
  @type account :: struct()

  @typedoc "An `ExWaha.Recipient` struct or a phone string. Strings get normalized."
  @type recipient :: ExWaha.Recipient.t() | String.t()

  @doc """
  Send a text message via the safety gate.

  The recipient can be:

    * a phone string in any format — non-digits are stripped
    * an `ExWaha.Recipient` struct (see `ExWaha.Recipient.new/1` and
      `ExWaha.Recipient.group/1`)

  ## Options

  Forwarded to the underlying provider. WAHA accepts `:reply_to` and
  `:link_preview`. Meta accepts `:preview_url`.

  ## Returns

    * `{:ok, response_body}` on 2xx
    * `{:error, %ExWaha.Error{}}` on rate-limit refusal, signature failure,
      transport errors, or non-2xx responses

  ## Example

      iex> account = build_account()
      iex> ExWaha.send_text(account, "+20 100 123 4567", "Hello!")
      {:ok, %{"id" => "msg_..."}}
  """
  @spec send_text(account(), recipient(), String.t(), keyword()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def send_text(account, recipient, text, opts \\ []) do
    SafeSend.dispatch(account, fn -> Provider.send_text(account, recipient, text, opts) end)
  end

  @doc """
  Send a media message (image, video, audio, document) via the safety gate.

  The `media` map must include `:type` (`:image | :video | :audio | :document`)
  and the provider-specific media descriptor.

  ## WAHA example

      ExWaha.send_media(account, "+201001234567", %{
        type: :image,
        file: %{url: "https://example.com/photo.jpg"},
        caption: "look at this"
      })

  ## Meta example

      ExWaha.send_media(meta_account, "+201001234567", %{
        type: :image,
        link: "https://example.com/photo.jpg",
        caption: "look at this"
      })
  """
  @spec send_media(account(), recipient(), map(), keyword()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def send_media(account, recipient, media, opts \\ []) do
    SafeSend.dispatch(account, fn -> Provider.send_media(account, recipient, media, opts) end)
  end

  @doc """
  Send a pre-approved Meta message template.

  Meta requires templates outside the 24-hour customer service window. WAHA
  returns `{:error, %ExWaha.Error{reason: :forbidden}}` since it does not
  participate in the template system.

  ## Options

    * `:language` — template language code (defaults to `"en_US"`)
    * `:components` — Meta template components list (header / body / button
      parameters)

  ## Example

      ExWaha.send_template(meta_account, "+201001234567", "order_shipped",
        language: "en_US",
        components: [
          %{
            type: "body",
            parameters: [%{type: "text", text: "TRACK-12345"}]
          }
        ]
      )
  """
  @spec send_template(account(), recipient(), String.t(), keyword()) ::
          {:ok, map()} | {:error, ExWaha.Error.t()}
  def send_template(account, recipient, template_name, opts \\ []) do
    SafeSend.dispatch(account, fn ->
      Provider.send_template(account, recipient, template_name, opts)
    end)
  end
end
