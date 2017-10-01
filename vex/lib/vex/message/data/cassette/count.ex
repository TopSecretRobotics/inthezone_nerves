defmodule Vex.Message.Data.Cassette.Count do

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

  def decode(req_id, subtopic, flag, ticks, << value >>) when is_integer(subtopic) do
    {:ok, new(req_id, flag, ticks, value)}
  end
  def decode(_, _, _, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Data.Cassette.Count do
  def encode(%@for{ req_id: req_id, flag: flag, ticks: ticks, value: value }) do
    data_message = Vex.Message.Data.new(req_id, Vex.Message.Data.Cassette, @for, flag, ticks, << value >>)
    Vex.FrameEncoder.encode(data_message)
  end
end
