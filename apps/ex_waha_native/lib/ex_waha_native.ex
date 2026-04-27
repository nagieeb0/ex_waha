defmodule ExWahaNative do
  @moduledoc """
  Native Elixir provider for ExWaha — no WAHA Docker container required.

  Talks the WhatsApp Multi-Device protocol via [`whatsmeow`](https://github.com/tulir/whatsmeow),
  a Go library, running as a single supervised sidecar process per BEAM node.
  Communication happens over stdio with length-prefixed JSON frames.

  ## Status

  v0.1.0 ships the architecture: supervision tree, wire protocol, Bridge
  GenServer, per-session GenServer, mix task to build the Go binary, and a
  Go skeleton that compiles. The actual whatsmeow integration on the Go side
  is a TODO — see `README.md` for the development plan.

  ## Why this exists

  `:ex_waha` (the wrapper) requires running a separate WAHA Docker container.
  That works but adds operational overhead. `:ex_waha_native` runs everything
  inside your BEAM release: one Go binary in `priv/`, no extra containers,
  no HTTP between you and WhatsApp.

  ## Usage

      account = ExWahaNative.Account.new(session: "profile_42")
      {:ok, _pid} = ExWahaNative.Session.Supervisor.ensure_started(account)

      # Same facade as the WAHA / Meta providers
      ExWaha.send_text(account, "+201001234567", "Hello!")
  """
end
