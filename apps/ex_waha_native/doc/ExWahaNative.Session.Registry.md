# `ExWahaNative.Session.Registry`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.2.0/lib/ex_waha_native/session/registry.ex#L1)

Process registry for `ExWahaNative.Session` instances, keyed by session name.

# `lookup`

```elixir
@spec lookup(String.t()) :: {:ok, pid()} | :error
```

# `via`

```elixir
@spec via(String.t()) :: {:via, Registry, {module(), String.t()}}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
