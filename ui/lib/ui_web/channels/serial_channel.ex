defmodule UiWeb.SerialChannel do
  use UiWeb, :channel

  def join("serial:ttyS0", _payload, socket) do
    # spawn(fn () ->
    #   :timer.sleep(1000)
    #   UiWeb.Endpoint.broadcast("serial:ttyS0", "data", %{ "data" => "data" })
    # end)
    {:ok, socket}
  end

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

  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end
end
