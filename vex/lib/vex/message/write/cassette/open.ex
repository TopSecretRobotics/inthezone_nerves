defmodule Vex.Message.Write.Cassette.Open do

  defstruct [
    req_id: nil,
    value: nil
  ]

  def new(req_id, value) when is_integer(value) do
    %__MODULE__{
      req_id: req_id,
      value: value
    }
  end

  def cast(req_id, _subtopic, value) do
    {:ok, new(req_id, value)}
  end

  def decode(req_id, subtopic, << value :: unsigned-big-integer-unit(1)-size(8) >>) when is_integer(subtopic) do
    {:ok, new(req_id, value)}
  end
  def decode(_, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Write.Cassette.Open do
  def encode(%@for{ req_id: req_id, value: value }) do
    write_message = Vex.Message.Write.new(req_id, Vex.Message.Write.Cassette, @for, << value :: unsigned-big-integer-unit(1)-size(8) >>)
    Vex.FrameEncoder.encode(write_message)
  end
end
