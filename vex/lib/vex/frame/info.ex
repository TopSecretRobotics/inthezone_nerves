defmodule Vex.Frame.INFO do

  @type t() :: %__MODULE__{
    topic: Vex.Stdint.uint8_t(),
    subtopic: Vex.Stdint.uint8_t(),
    value: binary()
  }

  defstruct [
    topic: nil,
    subtopic: nil,
    value: nil
  ]

  def new(topic, subtopic, value) do
    Vex.Frame.info(topic, subtopic, value)
  end

  def decode(<<
    topic,
    subtopic,
    len,
    value :: binary-size(len)
  >>) do
    {:ok, new(topic, subtopic, value)}
  end
  def decode(_) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Frame.INFO do
  def encode(%@for{ topic: topic, subtopic: subtopic, value: value }) do
    op = Vex.Frame.type_to_op!(@for)
    len = byte_size(value)
    <<
      op,
      topic,
      subtopic,
      len,
      value :: binary-size(len)
    >>
  end
end

defimpl OJSON.Encoder, for: Vex.Frame.INFO do
  def encode(%@for{ topic: topic, subtopic: subtopic, value: value }, options) do
    op = Vex.Frame.type_to_op!(@for)
    map = %{
      op: op,
      topic: topic,
      subtopic: subtopic,
      len: byte_size(value),
      value: :erlang.iolist_to_binary(:io_lib.format('~w', [value]))
    }
    OJSON.Encoder.encode(["INFO", map], options)
  end
end
