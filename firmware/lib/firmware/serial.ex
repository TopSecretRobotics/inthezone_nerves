defmodule Firmware.Serial do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  defmodule State do
    defstruct [
      pid: nil,
      active: false
    ]
  end

  alias __MODULE__.State, as: State

  def init([]) do
    {:ok, pid} = Nerves.UART.start_link()
    state = %State{
      pid: pid,
      active: false
    }
    :erlang.send_after(1000, self(), :reconnect)
    {:ok, state}
  end

  def handle_info({:nerves_uart, "ttyS0", data}, state = %State{ active: true }) do
    UiWeb.Endpoint.broadcast("serial:ttyS0", "data", %{ "data" => Base.encode64(data) })
    {:noreply, state}
  end
  def handle_info({:nerves_uart, "ttyS0", {:error, :eio}}, state = %State{ active: true }) do
    :erlang.send_after(1000, self(), :reconnect)
    state = %{ state | active: false }
    UiWeb.Endpoint.broadcast("serial:ttyS0", "status", %{ "error" => "eio" })
    {:noreply, state}
  end
  def handle_info(:reconnect, state = %State{ pid: pid, active: false }) do
    case Nerves.UART.open(pid, "ttyS0", speed: 230400, active: true) do
      :ok ->
        UiWeb.Endpoint.broadcast("serial:ttyS0", "status", %{ "ok" => true })
        state = %{ state | active: true }
        {:noreply, state}
      _ ->
        :erlang.send_after(1000, self(), :reconnect)
        {:noreply, state}
    end
  end
end