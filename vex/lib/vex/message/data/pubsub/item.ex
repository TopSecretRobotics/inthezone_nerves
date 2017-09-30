defmodule Vex.Message.Data.Pubsub.Item do

  defstruct [
    req_id: nil,
    index: nil,
    flag: nil,
    ticks: nil,
    sub_id: nil,
    sub_topic: nil,
    sub_subtopic: nil
  ]

  def new(req_id, index, flag, ticks, sub_id, sub_topic, sub_subtopic) when is_integer(index) and is_integer(sub_id) and is_integer(sub_topic) and is_integer(sub_subtopic) do
    %__MODULE__{
      req_id: req_id,
      index: index,
      flag: flag,
      ticks: ticks,
      sub_id: sub_id,
      sub_topic: sub_topic,
      sub_subtopic: sub_subtopic
    }
  end

  def decode(req_id, subtopic, flag, ticks, <<
    sub_id :: unsigned-big-integer-unit(1)-size(16),
    sub_topic :: unsigned-big-integer-unit(1)-size(8),
    sub_subtopic :: unsigned-big-integer-unit(1)-size(8)
  >>) when is_integer(subtopic) do
    {:ok, new(req_id, subtopic, flag, ticks, sub_id, sub_topic, sub_subtopic)}
  end
  def decode(_, _, _, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Data.Pubsub.Item do
  def encode(%@for{ req_id: req_id, index: index, flag: flag, ticks: ticks, sub_id: sub_id, sub_topic: sub_topic, sub_subtopic: sub_subtopic }) do
    data_message = Vex.Message.Data.new(req_id, Vex.Message.Data.Pubsub, index, flag, ticks, <<
      sub_id :: unsigned-big-integer-unit(1)-size(16),
      sub_topic :: unsigned-big-integer-unit(1)-size(8),
      sub_subtopic :: unsigned-big-integer-unit(1)-size(8)
    >>)
    Vex.FrameEncoder.encode(data_message)
  end
end
