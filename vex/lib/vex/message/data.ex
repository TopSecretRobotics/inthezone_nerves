defmodule Vex.Message.Data do

  @topic_pubsub 0x00
  @topic_clock 0x01
  @topic_motor 0x02
  @topic_smartmotor 0x03
  @topic_cassette 0x06

  defstruct [
    req_id: nil,
    topic: nil,
    subtopic: nil,
    flag: nil,
    ticks: nil,
    value: nil
  ]

  alias __MODULE__, as: Data

  def new(req_id, topic, subtopic, flag = %Vex.Frame.DATA.FLAG{}, ticks, value) when (is_nil(req_id) or is_integer(req_id)) and is_atom(topic) and (is_nil(ticks) or is_integer(ticks)) and is_binary(value) do
    %__MODULE__{
      req_id: req_id,
      topic: topic,
      subtopic: subtopic,
      flag: flag,
      ticks: ticks,
      value: value
    }
  end

  def decode(data_message = %Data{ topic: topic }) do
    topic.decode(data_message)
  end
  def decode(error_frame = %Vex.Frame.DATA{ flag: %{ error: true } }) do
    Vex.Message.Error.decode(error_frame)
  end
  def decode(%Vex.Frame.DATA{ req_id: req_id, topic: topic, subtopic: subtopic, flag: flag, ticks: ticks, value: value }) do
    with {:ok, type} <- topic_to_type(topic) do
      decode(new(req_id, type, subtopic, flag, ticks, value))
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
      @topic_pubsub -> Data.Pubsub
      @topic_clock -> Data.Clock
      @topic_motor -> Data.Motor
      @topic_smartmotor -> Data.Smartmotor
      @topic_cassette -> Data.Cassette
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
      Data.Pubsub -> @topic_pubsub
      Data.Clock -> @topic_clock
      Data.Motor -> @topic_motor
      Data.Smartmotor -> @topic_smartmotor
      Data.Cassette -> @topic_cassette
    end
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Data do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic, flag: flag, ticks: ticks, value: value }) do
    subtopic = topic.type_to_subtopic!(subtopic)
    topic = @for.type_to_topic!(topic)
    req_id = if is_nil(req_id), do: Vex.Local.Server.State.next_req_id(), else: req_id
    ticks = if is_nil(ticks), do: Vex.Local.Server.State.next_ticks(), else: ticks
    data_frame = Vex.Frame.data(req_id, topic, subtopic, flag, ticks, value)
    Vex.FrameEncoder.encode(data_frame)
  end
end
