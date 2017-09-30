defmodule Vex.Frame.DATA do

  @type t() :: %__MODULE__{
    req_id: Vex.Stdint.uint16_t(),
    topic: Vex.Stdint.uint8_t(),
    subtopic: Vex.Stdint.uint8_t(),
    flag: Vex.Stdint.uint8_t(),
    ticks: Vex.Stdint.uint32_t(),
    value: binary()
  }

  defstruct [
    req_id: nil,
    topic: nil,
    subtopic: nil,
    flag: nil,
    ticks: nil,
    value: nil
  ]

  def new(req_id, topic, subtopic, flag, ticks, value) do
    Vex.Frame.data(req_id, topic, subtopic, flag, ticks, value)
  end

  def decode(<<
    req_id :: unsigned-big-integer-unit(1)-size(16),
    topic,
    subtopic,
    flag,
    ticks :: unsigned-big-integer-unit(1)-size(32),
    len,
    value :: binary-size(len)
  >>) do
    {:ok, new(req_id, topic, subtopic, flag, ticks, value)}
  end
  def decode(_) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Frame.DATA do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic, flag: flag, ticks: ticks, value: value }) do
    op = Vex.Frame.type_to_op!(@for)
    len = byte_size(value)
    <<
      op,
      req_id :: unsigned-big-integer-unit(1)-size(16),
      topic,
      subtopic,
      (Vex.FrameEncoder.encode(flag)) :: binary-size(1),
      ticks :: unsigned-big-integer-unit(1)-size(32),
      len,
      value :: binary-size(len)
    >>
  end
end

defimpl OJSON.Encoder, for: Vex.Frame.DATA do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic, flag: flag, ticks: ticks, value: value }, options) do
    op = Vex.Frame.type_to_op!(@for)
    map = %{
      op: op,
      req_id: req_id,
      topic: topic,
      subtopic: subtopic,
      flag: flag,
      ticks: ticks,
      len: byte_size(value),
      value: :erlang.iolist_to_binary(:io_lib.format('~w', [value]))
    }
    OJSON.Encoder.encode(["DATA", map], options)
  end
end
