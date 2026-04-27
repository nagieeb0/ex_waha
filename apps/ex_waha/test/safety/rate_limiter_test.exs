defmodule ExWaha.Safety.RateLimiterTest do
  use ExUnit.Case, async: true

  alias ExWaha.Safety.RateLimiter

  test "starts full" do
    bucket = RateLimiter.new(5, 1.0)
    assert bucket.tokens == 5.0
  end

  test "take consumes tokens" do
    # Use a slow refill rate so the test isn't sensitive to scheduler jitter
    # between the two `take/2` calls.
    bucket = RateLimiter.new(3, 0.001)
    {:ok, b1} = RateLimiter.take(bucket, 1)
    assert_in_delta b1.tokens, 2.0, 0.05
    {:ok, b2} = RateLimiter.take(b1, 2)
    assert_in_delta b2.tokens, 0.0, 0.05
  end

  test "take returns wait time when empty" do
    bucket = RateLimiter.new(1, 1.0)
    {:ok, bucket} = RateLimiter.take(bucket, 1)
    {:error, ms_to_wait, _} = RateLimiter.take(bucket, 1)
    assert ms_to_wait > 0
    # 1 token at 1/s should be ~1000ms (minus refill since take)
    assert ms_to_wait <= 1100
  end

  test "refills over time" do
    bucket = RateLimiter.new(2, 100.0)
    {:ok, bucket} = RateLimiter.take(bucket, 2)
    Process.sleep(50)
    {:ok, bucket} = RateLimiter.take(bucket, 1)
    # After ~50ms at 100/s, ~5 tokens were available; took 1 -> ~4 (capped at 2)
    assert bucket.tokens >= 0.0
  end
end
