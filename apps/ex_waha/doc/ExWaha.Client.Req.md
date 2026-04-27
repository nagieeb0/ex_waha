# `ExWaha.Client.Req`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.1.0/lib/ex_waha/client/req.ex#L1)

Default `ExWaha.Client` implementation backed by `Req`.

Returns `{:ok, response}` on any HTTP response (caller maps status to error)
and `{:error, %ExWaha.Error{}}` on transport failures.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
