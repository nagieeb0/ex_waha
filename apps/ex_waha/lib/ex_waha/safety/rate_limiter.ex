defmodule ExWaha.Safety.RateLimiter do
  @moduledoc """
  Pure token-bucket rate limiter.

  This module is data-only — caller threads the bucket through state. The
  per-session `ExWaha.Session.Server` keeps one bucket per WhatsApp account.

  Why per-account: WhatsApp's rate limits are tracked per phone number, not
  per server. A global limiter would either over-throttle small tenants or
  under-throttle big ones.
  """

  @type t :: %__MODULE__{
          capacity: pos_integer(),
          refill_per_second: float(),
          tokens: float(),
          last_refill: integer()
        }

  defstruct [:capacity, :refill_per_second, :tokens, :last_refill]

  @spec new(pos_integer(), float()) :: t()
  def new(capacity, refill_per_second)
      when is_integer(capacity) and capacity > 0 and is_number(refill_per_second) do
    %__MODULE__{
      capacity: capacity,
      refill_per_second: refill_per_second * 1.0,
      tokens: capacity * 1.0,
      last_refill: now_ms()
    }
  end

  @spec take(t(), pos_integer()) :: {:ok, t()} | {:error, non_neg_integer(), t()}
  def take(%__MODULE__{} = bucket, amount \\ 1) do
    bucket = refill(bucket)

    if bucket.tokens >= amount do
      {:ok, %{bucket | tokens: bucket.tokens - amount}}
    else
      missing = amount - bucket.tokens
      ms_to_wait = trunc(missing / bucket.refill_per_second * 1000)
      {:error, ms_to_wait, bucket}
    end
  end

  @spec resize(t(), pos_integer(), float()) :: t()
  def resize(%__MODULE__{} = bucket, capacity, refill_per_second) do
    %{
      bucket
      | capacity: capacity,
        refill_per_second: refill_per_second * 1.0,
        tokens: min(bucket.tokens, capacity * 1.0)
    }
  end

  defp refill(%__MODULE__{} = bucket) do
    now = now_ms()
    elapsed_s = (now - bucket.last_refill) / 1000
    new_tokens = min(bucket.capacity * 1.0, bucket.tokens + elapsed_s * bucket.refill_per_second)
    %{bucket | tokens: new_tokens, last_refill: now}
  end

  defp now_ms, do: System.monotonic_time(:millisecond)
end
