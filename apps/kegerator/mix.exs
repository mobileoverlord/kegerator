defmodule Kegerator.Mixfile do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  def project do
    [app: :kegerator,
     version: "0.1.0",
     target: @target,
     archives: [nerves_bootstrap: "~> 0.2"],
     deps_path: "../../deps/#{@target}",
     build_path: "../../_build/#{@target}",
     config_path: "../../config/config.exs",
     lockfile: "../../mix.lock",
     kernel_modules: kernel_modules(@target),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(@target),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application, do: application(@target)
  def application("rpi3") do
    [mod: {Kegerator.Application, []},
     extra_applications: [:logger, :runtime_tools]]
  end

  def application(_) do
    [extra_applications: [:logger]]
  end

  def deps do
    [{:nerves, github: "nerves-project/nerves", override: true},
     {:nerves_firmware_http, github: "nerves-project/nerves_firmware_http"}]
    ++ deps(@target)
  end

  def deps("host") do
    []
  end

  def deps("rpi3") do
    [{:kegerator_system_rpi3, in_umbrella: true},
     {:nerves_interim_wifi, "~> 0.2"},
     {:elixir_ale, "~> 0.1"}]
  end

  def kernel_modules("rpi3") do
    ["brcmfmac"]
  end
  def kernel_modules(_), do: []

  def aliases("rpi3") do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end
  def aliases(_), do: []

end
