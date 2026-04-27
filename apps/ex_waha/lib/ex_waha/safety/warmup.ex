defmodule ExWaha.Safety.Warmup do
  @moduledoc """
  Account warmup curve.

  WhatsApp's anti-spam systems are most aggressive against new numbers and
  numbers that suddenly start sending more. A new account should send slowly
  and ramp up over days. This module computes the bucket parameters for a
  given account age.
  """

  @typedoc "Bucket parameters: {capacity, refill_per_second}."
  @type bucket_params :: {pos_integer(), float()}

  @spec params(integer(), keyword()) :: bucket_params()
  def params(account_age_days, config) when is_integer(account_age_days) do
    warmup_days = Keyword.get(config, :warmup_days, 14)
    cap_min = Keyword.get(config, :warmup_capacity, 5)
    cap_max = Keyword.get(config, :capacity, 30)
    refill_min = Keyword.get(config, :warmup_refill_per_second, 0.2)
    refill_max = Keyword.get(config, :refill_per_second, 1.0)

    cond do
      account_age_days < 0 ->
        {cap_min, refill_min}

      account_age_days >= warmup_days ->
        {cap_max, refill_max}

      true ->
        ratio = account_age_days / warmup_days
        capacity = round(cap_min + (cap_max - cap_min) * ratio)
        refill = refill_min + (refill_max - refill_min) * ratio
        {capacity, refill}
    end
  end

  @spec random_jitter_ms(keyword()) :: non_neg_integer()
  def random_jitter_ms(config) do
    case Keyword.get(config, :jitter_ms, {300, 1500}) do
      {min_ms, max_ms} when max_ms > min_ms -> min_ms + :rand.uniform(max_ms - min_ms)
      n when is_integer(n) -> n
      _ -> 0
    end
  end
end
