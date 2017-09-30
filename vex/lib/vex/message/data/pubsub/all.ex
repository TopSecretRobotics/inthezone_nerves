defmodule Vex.Message.Data.Pubsub.All do

  defstruct [
    req_id: nil,
    flag: nil,
    ticks: nil
  ]

  def new(req_id, flag, ticks) do
    %__MODULE__{
      req_id: req_id,
      flag: flag,
      ticks: ticks
    }
  end

  def decode(req_id, subtopic, flag, ticks, <<>>) when is_integer(subtopic) do
    {:ok, new(req_id, flag, ticks)}
  end
  def decode(_, _, _, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Data.Pubsub.All do
  def encode(%@for{ req_id: req_id, flag: flag, ticks: ticks }) do
    data_message = Vex.Message.Data.new(req_id, Vex.Message.Data.Pubsub, @for, flag, ticks, <<>>)
    Vex.FrameEncoder.encode(data_message)
  end
end
