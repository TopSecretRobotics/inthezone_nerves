defmodule Vex.Message.Write.Motor.Item do

  defstruct [
    req_id: nil,
    index: nil,
    value: nil
  ]

  def new(req_id, index, value) when is_integer(index) and is_integer(value) do
    %__MODULE__{
      req_id: req_id,
      index: index,
      value: value
    }
  end

  def cast(req_id, subtopic, value) do
    {:ok, new(req_id, subtopic, value)}
  end

  def decode(req_id, subtopic, << value :: signed-big-integer-unit(1)-size(8) >>) when is_integer(subtopic) do
    {:ok, new(req_id, subtopic, value)}
  end
  def decode(_, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Write.Motor.Item do
  def encode(%@for{ req_id: req_id, index: index, value: value }) do
    write_message = Vex.Message.Write.new(req_id, Vex.Message.Write.Motor, index, << value :: signed-big-integer-unit(1)-size(8) >>)
    Vex.FrameEncoder.encode(write_message)
  end
end
