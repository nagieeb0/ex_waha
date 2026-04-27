# `ExWaha.Client`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/client.ex#L1)

HTTP client behaviour. Implementations: `ExWaha.Client.Req` (default) and
`ExWaha.ClientMock` (test only).

Designed so all transport concerns are a single mockable seam.

# `body`

```elixir
@type body() :: nil | binary() | map() | list()
```

# `error`

```elixir
@type error() :: {:error, ExWaha.Error.t()}
```

# `headers`

```elixir
@type headers() :: [{String.t(), String.t()}]
```

# `method`

```elixir
@type method() :: :get | :post | :put | :patch | :delete
```

# `opts`

```elixir
@type opts() :: keyword()
```

# `response`

```elixir
@type response() ::
  {:ok, %{status: non_neg_integer(), headers: headers(), body: any()}}
```

# `url`

```elixir
@type url() :: String.t()
```

# `request`

```elixir
@callback request(method(), url(), headers(), body(), opts()) :: response() | error()
```

# `impl`

```elixir
@spec impl() :: module()
```

# `request`

```elixir
@spec request(method(), url(), headers(), body(), opts()) :: response() | error()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
