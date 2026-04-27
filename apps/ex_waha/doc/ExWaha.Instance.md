# `ExWaha.Instance`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/instance.ex#L1)

Configuration for a single WAHA server.

An `Instance` describes how to reach a WAHA Docker container. Multiple
instances coexist — pass the right one per call. No global state.

# `t`

```elixir
@type t() :: %ExWaha.Instance{
  api_key: nil | String.t(),
  base_url: String.t(),
  headers: [{String.t(), String.t()}],
  http_client: nil | module(),
  receive_timeout_ms: pos_integer(),
  timeout_ms: pos_integer()
}
```

# `new`

```elixir
@spec new(keyword()) :: t()
```

Build an `Instance` from keyword opts.

## Required

  * `:base_url` — full URL to the WAHA server (e.g. `"http://waha:3000"`)

## Optional

  * `:api_key` — `X-Api-Key` header value (set if WAHA was started with one)
  * `:http_client` — module implementing `ExWaha.Client` (defaults to
    `ExWaha.Client.Req` via application config)
  * `:timeout_ms` — connect timeout (default `10_000`)
  * `:receive_timeout_ms` — response timeout (default `30_000`)
  * `:headers` — additional request headers (default `[]`)

## Example

    ExWaha.Instance.new(
      base_url: "http://waha.internal:3000",
      api_key: System.fetch_env!("WAHA_API_KEY")
    )

---

*Consult [api-reference.md](api-reference.md) for complete listing*
