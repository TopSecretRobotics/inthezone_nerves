defmodule Vex.Message.Read do

  @topic_pubsub 0x00
  @topic_clock 0x01
  @topic_motor 0x02
  @topic_smartmotor 0x03

  defstruct [
    req_id: nil,
    topic: nil,
    subtopic: nil
  ]

  alias __MODULE__, as: Read

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

  def decode(read_message = %Read{ topic: topic }) do
    topic.decode(read_message)
  end
  def decode(%Vex.Frame.READ{ req_id: req_id, topic: topic, subtopic: subtopic }) do
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
      _ when topic in [@topic_pubsub, :pubsub] -> Read.Pubsub
      _ when topic in [@topic_clock, :clock] -> Read.Clock
      _ when topic in [@topic_motor, :motor] -> Read.Motor
      _ when topic in [@topic_smartmotor, :smartmotor] -> Read.Smartmotor
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
      Read.Pubsub -> @topic_pubsub
      Read.Clock -> @topic_clock
      Read.Motor -> @topic_motor
      Read.Smartmotor -> @topic_smartmotor
    end
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Read do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic }) do
    subtopic = topic.type_to_subtopic!(subtopic)
    topic = @for.type_to_topic!(topic)
    req_id = if is_nil(req_id), do: Vex.Local.Server.State.next_req_id(), else: req_id
    read_frame = Vex.Frame.read(req_id, topic, subtopic)
    Vex.FrameEncoder.encode(read_frame)
  end
end
