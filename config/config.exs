import Config

config :ex_waha, default_client: ExWaha.Client.Req

# Conservative defaults to reduce ban risk on personal/business numbers.
# Consult WhatsApp ToS and your provider's policies before raising these.
config :ex_waha, :rate_limit,
  capacity: 30,
  refill_per_second: 1.0,
  warmup_days: 14,
  warmup_capacity: 5,
  warmup_refill_per_second: 0.2,
  jitter_ms: {300, 1500}

import_config "#{config_env()}.exs"
