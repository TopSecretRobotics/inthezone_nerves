defmodule Vex.Message.Info do

  @topic_network 0x04
  @topic_robot 0x05

  defstruct [
    topic: nil,
    subtopic: nil,
    value: nil
  ]

  alias __MODULE__, as: Info

  def new(topic, subtopic, value) when is_atom(topic) and is_binary(value) do
    %__MODULE__{
      topic: topic,
      subtopic: subtopic,
      value: value
    }
  end

  def decode(info_message = %Info{ topic: topic }) do
    topic.decode(info_message)
  end
  def decode(%Vex.Frame.INFO{ topic: topic, subtopic: subtopic, value: value }) do
    with {:ok, type} <- topic_to_type(topic) do
      decode(new(type, subtopic, value))
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

  def topic_to_type!(topic) when is_integer(topic) do
    case topic do
      @topic_network -> Info.Network
      @topic_robot -> Info.Robot
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
      Info.Network -> @topic_network
      Info.Robot -> @topic_robot
    end
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Info do
  def encode(%@for{ topic: topic, subtopic: subtopic, value: value }) do
    subtopic = topic.type_to_subtopic!(subtopic)
    topic = @for.type_to_topic!(topic)
    info_frame = Vex.Frame.info(topic, subtopic, value)
    Vex.FrameEncoder.encode(info_frame)
  end
end
