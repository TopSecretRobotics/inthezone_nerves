defmodule Vex.Message.Data.Clock.Now do

  defstruct [
    req_id: nil,
    flag: nil,
    ticks: nil,
    value: nil
  ]

  def new(req_id, flag, ticks, value) do
    %__MODULE__{
      req_id: req_id,
      flag: flag,
      ticks: ticks,
      value: value
    }
  end

  def decode(req_id, subtopic, flag, ticks, << value :: unsigned-big-integer-unit(1)-size(64) >>) when is_integer(subtopic) do
    {:ok, new(req_id, flag, ticks, value)}
  end
  def decode(_, _, _, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Data.Clock.Now do
  def encode(%@for{ req_id: req_id, flag: flag, ticks: ticks, value: value }) do
    data_message = Vex.Message.Data.new(req_id, Vex.Message.Data.Clock, @for, flag, ticks, << value :: unsigned-big-integer-unit(1)-size(64) >>)
    Vex.FrameEncoder.encode(data_message)
  end
end
