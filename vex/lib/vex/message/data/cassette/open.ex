defmodule Vex.Message.Data.Cassette.Open do

  defstruct [
    req_id: nil,
    flag: nil,
    ticks: nil,
    value: nil
  ]

  def new(req_id, flag, ticks, {value, position}) do
    %__MODULE__{
      req_id: req_id,
      flag: flag,
      ticks: ticks,
      value: {value, position}
    }
  end

  def decode(req_id, subtopic, flag, ticks, << value, position :: unsigned-big-integer-unit(1)-size(32) >>) when is_integer(subtopic) do
    {:ok, new(req_id, flag, ticks, {value, position})}
  end
  def decode(_, _, _, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Data.Cassette.Open do
  def encode(%@for{ req_id: req_id, flag: flag, ticks: ticks, value: {value, position} }) do
    data_message = Vex.Message.Data.new(req_id, Vex.Message.Data.Cassette, @for, flag, ticks, << value, position :: unsigned-big-integer-unit(1)-size(32) >>)
    Vex.FrameEncoder.encode(data_message)
  end
end
