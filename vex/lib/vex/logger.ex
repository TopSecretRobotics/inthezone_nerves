defmodule Vex.Logger do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def init([]) do
    # :ok = :vex_robot_event.add_handler(:vex_robot_event_handler, :erlang.self())
    # :ok = :vex_server_event.add_handler(:vex_server_event_handler, :erlang.self())
    # :ok = Vex.Robot.Server.Socket.Events.subscribe_all()
    # :ok = Vex.Robot.Server.Events.subscribe_all()
    # :ok = Vex.Local.Server.Socket.Events.subscribe_all()
    :ok = Vex.Local.Server.Events.subscribe_all()
    {:ok, nil}
  end

  def handle_info(info, state) do
  #   if !ignore(info) do
      Logger.info("#{inspect info}")
  #   end
    {:noreply, state}
  end

  # @doc false
  # defp ignore(info) do
  #   case info do
  #     # {_, {:socket_in, _}} -> true
  #     # {_, {:socket_out, _}} -> true
  #     # {_, {:frame_in, %Vex.MessageFrame.PING{}}} -> true
  #     # {_, {:frame_out, %Vex.MessageFrame.PING{}}} -> true
  #     # {_, {:frame_in, %Vex.MessageFrame.PONG{}}} -> true
  #     # {_, {:frame_out, %Vex.MessageFrame.PONG{}}} -> true
  #     # {:vex_robot_event, {:socket_in, _}} -> true
  #     {:vex_robot_event, {:socket_out, _}} -> true
  #     {:vex_server_event, {:socket_in, _}} -> true
  #     _ -> false
  #   end
  # end
end