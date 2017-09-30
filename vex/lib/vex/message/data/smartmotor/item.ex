defmodule Vex.Message.Data.Smartmotor.Item do

  defstruct [
    req_id: nil,
    index: nil,
    flag: nil,
    ticks: nil,
    value: nil
  ]

  def new(req_id, index, flag, ticks, value) when is_integer(index) and is_integer(value) do
    %__MODULE__{
      req_id: req_id,
      index: index,
      flag: flag,
      ticks: ticks,
      value: value
    }
  end

  def decode(req_id, subtopic, flag, ticks, << value :: signed-big-integer-unit(1)-size(16) >>) when is_integer(subtopic) do
    {:ok, new(req_id, subtopic, flag, ticks, value)}
  end
  def decode(_, _, _, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Data.Smartmotor.Item do
  def encode(%@for{ req_id: req_id, index: index, flag: flag, ticks: ticks, value: value }) do
    data_message = Vex.Message.Data.new(req_id, Vex.Message.Data.Smartmotor, index, flag, ticks, << value :: signed-big-integer-unit(1)-size(16) >>)
    Vex.FrameEncoder.encode(data_message)
  end
end
