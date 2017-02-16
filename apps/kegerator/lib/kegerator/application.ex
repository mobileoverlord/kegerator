defmodule Kegerator.Application do
  use Application
  @interface :wlan0
  @kernel_modules Mix.Project.config[:kernel_modules] || []
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    temp_opts = Application.get_env(:kegerator, :temperature)
    # Define workers and child supervisors to be supervised
    children = [
      worker(Task, [fn -> init_kernel_modules() end], restart: :transient, id: Nerves.Init.KernelModules),
      worker(Kegerator.NetworkManager, [@interface]),
      worker(Task, [fn -> init_network() end], restart: :transient, id: Nerves.Init.Network),
      worker(Kegerator.Temperature, [temp_opts])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kegerator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def init_kernel_modules() do
    Enum.each(@kernel_modules, & System.cmd("modprobe", [&1]))
  end

  def init_network() do
    opts = Application.get_env(:kegerator, @interface)
    Nerves.InterimWiFi.setup(@interface, opts)
  end
end
