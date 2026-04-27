defmodule Mix.Tasks.ExWahaNative.BuildNative do
  @moduledoc """
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
  """

  use Mix.Task

  @shortdoc "Build the Go whatsmeow bridge binary"

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [target: :string])

    app_root = app_root()
    src_dir = Path.join([app_root, "native", "bridge"])
    out_dir = Path.join([app_root, "priv", "native"])
    out_path = Path.join(out_dir, "whatsmeow_bridge")

    File.mkdir_p!(out_dir)

    env = build_env(opts[:target])

    Mix.shell().info("Building Go bridge from #{src_dir} -> #{out_path}")

    cmd_opts = [cd: src_dir, env: env, into: IO.stream()]

    case System.cmd("go", ["build", "-o", out_path, "."], cmd_opts) do
      {_, 0} -> Mix.shell().info("Built #{out_path}")
      {_, code} -> Mix.raise("go build exited with status #{code}")
    end
  end

  defp build_env(nil), do: []

  defp build_env(target) do
    case String.split(target, "/") do
      [os, arch] -> [{"GOOS", os}, {"GOARCH", arch}]
      _ -> Mix.raise("--target must be in OS/ARCH form, e.g. linux/amd64")
    end
  end

  # Locate apps/ex_waha_native regardless of whether mix is invoked from the
  # umbrella root or from inside the app.
  defp app_root do
    cwd = File.cwd!()
    candidate_in_umbrella = Path.join([cwd, "apps", "ex_waha_native"])

    cond do
      File.dir?(Path.join([cwd, "native", "bridge"])) -> cwd
      File.dir?(Path.join([candidate_in_umbrella, "native", "bridge"])) -> candidate_in_umbrella
      true -> Mix.raise("could not locate ex_waha_native app root from #{cwd}")
    end
  end
end
