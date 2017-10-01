defmodule Vex.Message.Write.Cassette.Write do

  defstruct [
    req_id: nil,
    index: nil,
    value: nil
  ]

  def new(req_id, index, value) when is_integer(index) and is_binary(value) do
    %__MODULE__{
      req_id: req_id,
      index: index,
      value: value
    }
  end

  def cast(req_id, _subtopic, {index, value}) do
    {:ok, new(req_id, index, value)}
  end

  def decode(req_id, subtopic, << index :: unsigned-big-integer-unit(1)-size(8), value :: binary() >>) when is_integer(subtopic) do
    {:ok, new(req_id, index, value)}
  end
  def decode(_, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Write.Cassette.Write do
  def encode(%@for{ req_id: req_id, index: index, value: value }) do
    write_message = Vex.Message.Write.new(req_id, Vex.Message.Write.Cassette, @for, << index :: unsigned-big-integer-unit(1)-size(8), value :: binary() >>)
    Vex.FrameEncoder.encode(write_message)
  end
end
