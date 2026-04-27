# `ExWahaNative.Provider`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.2.0/lib/ex_waha_native/provider.ex#L1)

`ExWaha.Provider` implementation that routes through the Go bridge.

Registered with `ExWaha.Provider.register/2` at application start so that
`ExWaha.send_text(native_account, ...)` dispatches here transparently.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
