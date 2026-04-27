# Changelog

## [Unreleased]

## [0.1.0] - 2026-04-27

### Added
- `ExWahaPhoenix.WebhookPlug` — mountable plug that verifies HMAC, parses
  the payload, and dispatches normalized events to a `Handler` behaviour
  module. Supports MFA / function / static account resolution per request.
- `ExWahaPhoenix.WebhookPlug.read_body/2` — body reader that caches the raw
  body so signature verification still works after `Plug.Parsers` runs.
- `ExWahaPhoenix.Dashboard` — LiveView skeleton mountable under the host
  app's auth pipeline (compiled only when `:phoenix_live_view` is present).
