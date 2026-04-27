# `mix ex_waha_native.build_native`
[🔗](https://github.com/nagieeb/ex_waha/blob/v0.2.0/lib/mix/tasks/ex_waha_native.build_native.ex#L1)

Build the Go bridge binary.

Compiles `native/bridge` into `priv/native/whatsmeow_bridge`. Requires the
Go toolchain (`go` ≥ 1.21) on PATH.

    mix ex_waha_native.build_native

## Options

  * `--target TRIPLE` — cross-compile (e.g. `linux/amd64`, `darwin/arm64`).
    Defaults to the host platform.

## Output

The compiled binary is placed at `priv/native/whatsmeow_bridge`. This path
is what `ExWahaNative.Bridge` looks up at runtime via
`Application.app_dir/2`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
