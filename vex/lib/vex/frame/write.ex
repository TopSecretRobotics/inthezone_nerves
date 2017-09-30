defmodule Vex.Frame.WRITE do

  @type t() :: %__MODULE__{
    req_id: Vex.Stdint.uint16_t(),
    topic: Vex.Stdint.uint8_t(),
    subtopic: Vex.Stdint.uint8_t(),
    value: binary()
  }

  defstruct [
    req_id: nil,
    topic: nil,
    subtopic: nil,
    value: nil
  ]

  def new(req_id, topic, subtopic, value) do
    Vex.Frame.write(req_id, topic, subtopic, value)
  end

  def decode(<<
    req_id :: unsigned-big-integer-unit(1)-size(16),
    topic,
    subtopic,
    len,
    value :: binary-size(len)
  >>) do
    {:ok, new(req_id, topic, subtopic, value)}
  end
  def decode(_) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Frame.WRITE do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic, value: value }) do
    op = Vex.Frame.type_to_op!(@for)
    len = byte_size(value)
    <<
      op,
      req_id :: unsigned-big-integer-unit(1)-size(16),
      topic,
      subtopic,
      len,
      value :: binary-size(len)
    >>
  end
end

defimpl OJSON.Encoder, for: Vex.Frame.WRITE do
  def encode(%@for{ req_id: req_id, topic: topic, subtopic: subtopic, value: value }, options) do
    op = Vex.Frame.type_to_op!(@for)
    map = %{
      op: op,
      req_id: req_id,
      topic: topic,
      subtopic: subtopic,
      len: byte_size(value),
      value: :erlang.iolist_to_binary(:io_lib.format('~w', [value]))
    }
    OJSON.Encoder.encode(["WRITE", map], options)
  end
end
