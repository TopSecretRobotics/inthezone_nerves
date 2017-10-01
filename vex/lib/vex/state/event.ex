defmodule Vex.State.Event do

  @autostart Vex.State.Autostart
  @pubsub Phoenix.PubSub

  def start_link() do
    Phoenix.PubSub.PG2.start_link(__MODULE__, [])
  end

  def broadcast(topic, message) do
    @pubsub.broadcast(__MODULE__, topic, message)
  end

  def broadcast!(topic, message) do
    @pubsub.broadcast!(__MODULE__, topic, message)
  end

  def subscribe(module, topic) do
    with :ok <- @pubsub.subscribe(__MODULE__, topic) do
      @autostart.subscribe(module, :erlang.self())
    end
  end

  def subscribe(module, pid, topic) do
    with :ok <- @pubsub.subscribe(__MODULE__, pid, topic) do
      @autostart.subscribe(module, pid)
    end
  end

  def subscribe(module, pid, topic, opts) do
    with :ok <- @pubsub.subscribe(__MODULE__, pid, topic, opts) do
      @autostart.subscribe(module, pid)
    end
  end

  def unsubscribe(module, topic) do
    with :ok <- @pubsub.unsubscribe(__MODULE__, topic) do
      @autostart.unsubscribe(module, :erlang.self())
    end
  end

  def unsubscribe(module, pid, topic) do
    with :ok <- @pubsub.unsubscribe(__MODULE__, pid, topic) do
      @autostart.subscribe(module, pid)
    end
  end

end