defmodule Vex.Message.Write do

  @topic_motor 0x02

  defstruct [
    req_id: nil,
    topic: nil,
    subtopic: nil,
    value: nil
  ]

  alias __MODULE__, as: Write

  def new(req_id, topic, subtopic, value) when (is_nil(req_id) or is_integer(req_id)) and is_atom(topic) and is_binary(value) do
    %__MODULE__{
      req_id: req_id,
      topic: topic,
      subtopic: subtopic,
      value: value
    }
  end

  def cast(req_id, topic, subtopic, value) do
    with {:ok, type} <- topic_to_type(topic) do
      type.cast(req_id, subtopic, value)
    end
  end

  def decode(write_message = %Write{ topic: topic }) do
    topic.decode(write_message)
  end
  def decode(%Vex.Frame.WRITE{ req_id: req_id, topic: topic, subtopic: subtopic, value: value }) do
    with {:ok, type} <- topic_to_type(topic) do
      decode(new(req_id, type, subtopic, value))
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
      _ when topic in [@topic_motor, :motor] -> Write.Motor
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
      Write.Motor -> @topic_motor
    end
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Write do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic, value: value }) do
    subtopic = topic.type_to_subtopic!(subtopic)
    topic = @for.type_to_topic!(topic)
    req_id = if is_nil(req_id), do: Vex.Local.Server.State.next_req_id(), else: req_id
    write_frame = Vex.Frame.write(req_id, topic, subtopic, value)
    Vex.FrameEncoder.encode(write_frame)
  end
end
