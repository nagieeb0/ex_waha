# Changelog

All notable changes to `:ex_waha` will be documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/) and the project adheres to
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-04-27

### Added
- Provider-agnostic facade (`ExWaha`) with `send_text/4`, `send_media/4`,
  `send_template/4`.
- `ExWaha.Provider` behaviour with WAHA and Meta Cloud API implementations.
- Configurable HTTP transport via `ExWaha.Client` behaviour with a
  `Req`-backed default and a Mox-friendly seam for tests.
- Per-account OTP layer: `Session.Registry`, `Session.Supervisor`,
  `Session.Server` with token-bucket rate limiting, warmup ramp, and
  randomized jitter.
- Webhook subsystem: normalized `Event` struct for both providers, HMAC
  signature verification (SHA-512 for WAHA, SHA-256 for Meta), and a
  pluggable `Handler` behaviour.
- WAHA REST API surface: `Sessions`, `Auth`, `Messages`, `Chats`, `Contacts`,
  `Groups`, `Presence`, `Profile`.
- Telemetry spans on every request plus discrete events for throttle and
  status changes.
