defmodule Kegerator.NetworkManager do
  use GenServer
  require Logger

  @app Mix.Project.config[:app]

  def start_link(iface) do
    GenServer.start_link(__MODULE__, iface)
  end

  def init(iface) do
    iface = to_string(iface)
    :os.cmd 'epmd -daemon'
    {:ok, pid} = Registry.register(Nerves.Udhcpc, iface, [])
    {:ok, %{registry: pid, iface: iface}}
  end

  def handle_info({Nerves.Udhcpc, event, %{ipv4_address: ip}}, s)
    when event in [:bound, :renew] do
    Logger.info "IP Address Changed"
    :net_kernel.stop()
    :net_kernel.start([:"#{@app}@#{ip}"])
    {:noreply, s}
  end

  def handle_info(_event, s) do
    {:noreply, s}
  end
end
