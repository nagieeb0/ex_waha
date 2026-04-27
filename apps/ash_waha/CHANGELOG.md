# Changelog

## [Unreleased]

## [0.1.0] - 2026-04-27

### Added
- `AshWaha` Spark DSL extension with a `whatsapp` section
  (`account`, `session_name`, `on_event`).
- `AshWaha.Changes.SendText` — Ash change that calls `ExWaha.send_text/4`
  inside an action, supporting literal `text` or `text_arg` (action
  argument) and a configurable `recipient_attr`.

### Known limitations
- Auto-injected standard actions (`:start_session`, `:request_qr`, etc.)
  are planned but not implemented in 0.1.0.
- `on_event` is parsed but not yet wired to webhook dispatch.
