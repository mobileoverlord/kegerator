defmodule Kegerator.Temperature do
  use GenServer
  require Logger

  @interval 2000
  @on 1
  @off 0

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def set_temperature(temp) do
    GenServer.call(__MODULE__, {:set_temperature, temp})
  end

  def get_current_temperature() do
    GenServer.call(__MODULE__, :get_current_temperature)
  end

  def set_drift(temp) do
    GenServer.call(__MODULE__, {:set_drift, temp})
  end

  def init(opts) do
    Logger.debug "Starting Temperature Server"
    temperature = opts[:temperature] || raise "No temperature configured"
    drift = opts[:drift] || 2
    relay_pin = opts[:relay_pin]
    {:ok, pid} = Gpio.start_link(relay_pin, :output)
    send(self(), :read_temp)
    {:ok, %{
      relay: pid,
      device: "/sys/bus/iio/devices/iio:device0/in_temp_input",
      current_temp: nil,
      temperature: temperature,
      drift: drift,
      status: :off
    }}
  end

  def handle_call({:set_temperature, temp}, _from, s) do
    {:reply, {:ok, temp}, %{s | temperature: temp}}
  end

  def handle_call(:get_current_temperature, _from, s) do
    {:reply, {:ok, s.current_temp}, s}
  end

  def handle_call({:set_drift, temp}, _from, s) do
    {:reply, {:ok, temp}, %{s | drift: temp}}
  end

  def handle_info(:read_temp, s) do
    s =
      case File.read(s.device) do
        {:ok, temp} ->

          {temp, _} =
            String.strip(temp)
            |> String.split_at(-3)
            |> Tuple.to_list
            |> Enum.join(".")
            |> Float.parse
          f = ((temp * 9) / 5) + 32
          f = Float.round(f, 2)
          Logger.debug "Read Temp: #{inspect f}"
          s = %{s | current_temp: f}
          Process.send_after(self(), :read_temp, @interval)
          check_set(s)
        {:error, _} ->
          Process.send_after(self(), :read_temp, 250)
          s
      end
    {:noreply, s}
  end

  def check_set(%{status: :off} = s) do
    if s.current_temp > (s.temperature + s.drift) do
      Logger.debug "Temp: #{inspect s.current_temp} Relay On"
      Gpio.write(s.relay, @on)
      %{s | status: :on}
    else
      s
    end
  end

  def check_set(%{status: :on} = s) do
    if s.current_temp < (s.temperature - s.drift) do
      Logger.debug "Temp: #{inspect s.current_temp} Relay Off"
      Gpio.write(s.relay, @off)
      %{s | status: :off}
    else
      s
    end
  end
end
