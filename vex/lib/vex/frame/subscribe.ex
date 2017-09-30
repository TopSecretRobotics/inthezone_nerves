defmodule Vex.Frame.SUBSCRIBE do

  @type t() :: %__MODULE__{
    req_id: Vex.Stdint.uint16_t(),
    topic: Vex.Stdint.uint8_t(),
    subtopic: Vex.Stdint.uint8_t()
  }

  defstruct [
    req_id: nil,
    topic: nil,
    subtopic: nil
  ]

  def new(req_id, topic, subtopic) do
    Vex.Frame.subscribe(req_id, topic, subtopic)
  end

  def decode(<<
    req_id :: unsigned-big-integer-unit(1)-size(16),
    topic,
    subtopic
  >>) do
    {:ok, new(req_id, topic, subtopic)}
  end
  def decode(_) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Frame.SUBSCRIBE do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic }) do
    op = Vex.Frame.type_to_op!(@for)
    <<
      op,
      req_id :: unsigned-big-integer-unit(1)-size(16),
      topic,
      subtopic
    >>
  end
end

defimpl OJSON.Encoder, for: Vex.Frame.SUBSCRIBE do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic }, options) do
    op = Vex.Frame.type_to_op!(@for)
    map = %{
      op: op,
      req_id: req_id,
      topic: topic,
      subtopic: subtopic
    }
    OJSON.Encoder.encode(["SUBSCRIBE", map], options)
  end
end
