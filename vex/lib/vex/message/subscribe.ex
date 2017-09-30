defmodule Vex.Message.Subscribe do

  @topic_clock 0x01
  @topic_motor 0x02
  @topic_smartmotor 0x03
  @topic_all 0xff

  defstruct [
    req_id: nil,
    topic: nil,
    subtopic: nil
  ]

  alias __MODULE__, as: Subscribe

  def new(req_id, topic, subtopic) when (is_nil(req_id) or is_integer(req_id)) and is_atom(topic) do
    %__MODULE__{
      req_id: req_id,
      topic: topic,
      subtopic: subtopic
    }
  end

  def cast(req_id, topic, subtopic) do
    with {:ok, type} <- topic_to_type(topic) do
      type.cast(req_id, subtopic)
    end
  end

  def decode(subscribe_message = %Subscribe{ topic: topic }) do
    topic.decode(subscribe_message)
  end
  def decode(%Vex.Frame.SUBSCRIBE{ req_id: req_id, topic: topic, subtopic: subtopic }) do
    with {:ok, type} <- topic_to_type(topic) do
      decode(new(req_id, type, subtopic))
    else _ ->
      :error
    end
  end
  def decode(binary) when is_binary(binary) do
    with {:ok, frame} <- Vex.Frame.decode(binary) do
      decode(frame)
    else _ ->
      :error
    end
  end
  def decode(_) do
    :error
  end

  def topic_to_type(topic) do
    try do
      {:ok, topic_to_type!(topic)}
    catch _,_ ->
      :error
    end
  end

  def topic_to_type!(topic) do
    case topic do
      _ when topic in [@topic_clock, :clock] -> Subscribe.Clock
      _ when topic in [@topic_motor, :motor] -> Subscribe.Motor
      _ when topic in [@topic_smartmotor, :smartmotor] -> Subscribe.Smartmotor
      _ when topic in [@topic_all, :all] -> Subscribe.All
    end
  end

  def type_to_topic(type) do
    try do
      {:ok, type_to_topic!(type)}
    catch _,_ ->
      :error
    end
  end

  def type_to_topic!(type) when is_atom(type) do
    case type do
      Subscribe.Clock -> @topic_clock
      Subscribe.Motor -> @topic_motor
      Subscribe.Smartmotor -> @topic_smartmotor
      Subscribe.All -> @topic_all
    end
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Subscribe do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic }) do
    subtopic = topic.type_to_subtopic!(subtopic)
    topic = @for.type_to_topic!(topic)
    req_id = if is_nil(req_id), do: Vex.Local.Server.State.next_req_id(), else: req_id
    subscribe_frame = Vex.Frame.subscribe(req_id, topic, subtopic)
    Vex.FrameEncoder.encode(subscribe_frame)
  end
end
