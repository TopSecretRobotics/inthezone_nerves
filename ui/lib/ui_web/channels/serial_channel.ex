defmodule UiWeb.SerialChannel do
  use UiWeb, :channel

  @impl Phoenix.Channel
  def join("serial:vex", _payload, socket) do
    :ok = :vex_server_event.add_handler(:vex_server_event_handler, :erlang.self())
    send(self(), :check_server_connection)
    {:ok, socket}
  end

  @impl Phoenix.Channel
  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (serial:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # @impl Phoenix.Channel
  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  @impl Phoenix.Channel
  def handle_info(:check_server_connection, socket) do
    if Vex.Server.connected?() do
      push(socket, "server", %{ "event" => "connected" })
    else
      push(socket, "server", %{ "event" => "disconnected" })
    end
    {:noreply, socket}
  end
  def handle_info(info, socket) do
    case info do
      {:vex_server_event, :connected} ->
        push(socket, "server", %{ "event" => "connected" })
      {:vex_server_event, :disconnected} ->
        push(socket, "server", %{ "event" => "disconnected" })
      {:vex_server_event, {:frame_in, frame}} ->
        push(socket, "server", %{ "event" => "in", "message" => frame })
      {:vex_server_event, {:frame_out, frame}} ->
        push(socket, "server", %{ "event" => "out", "message" => frame })
      {:vex_server_event, {:socket_in, _}} ->
        :ok
      {:vex_server_event, {:socket_out, _}} ->
        :ok
      # _ ->
      #   # require Logger
      #   # Logger.info("info: #{inspect info}")
      #   :ok
    end
    {:noreply, socket}
  end
end
