defmodule Vex.Message.Error.BadSubtopic do

  defstruct [
    req_id: nil,
    topic: nil,
    subtopic: nil,
    flag: nil,
    ticks: nil
  ]

  def new(req_id, topic, subtopic, flag, ticks) do
    %__MODULE__{
      req_id: req_id,
      topic: topic,
      subtopic: subtopic,
      flag: flag,
      ticks: ticks
    }
  end

  def decode(req_id, topic, subtopic, flag, ticks) do
    {:ok, new(req_id, topic, subtopic, flag, ticks)}
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Error.BadSubtopic do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic, flag: flag, ticks: ticks }) do
    value = Vex.Message.Error.type_to_value(@for)
    data_message = Vex.Message.Data.new(req_id, topic, subtopic, flag, ticks, << value >>)
    Vex.FrameEncoder.encode(data_message)
  end
end
