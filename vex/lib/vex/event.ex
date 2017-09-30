defmodule Vex.Event do

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

  def subscribe(topic) do
    @pubsub.subscribe(__MODULE__, topic)
  end

  def subscribe(pid, topic) do
    @pubsub.subscribe(__MODULE__, pid, topic)
  end

  def subscribe(pid, topic, opts) do
    @pubsub.subscribe(__MODULE__, pid, topic, opts)
  end

  def unsubscribe(topic) do
    @pubsub.unsubscribe(__MODULE__, topic)
  end

  def unsubscribe(pid, topic) do
    @pubsub.unsubscribe(__MODULE__, pid, topic)
  end

end