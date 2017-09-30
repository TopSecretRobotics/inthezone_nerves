defmodule Vex.Message.Read.Clock.Now do

  defstruct [
    req_id: nil
  ]

  def new(req_id) do
    %__MODULE__{
      req_id: req_id
    }
  end

  def cast(req_id, _subtopic) do
    {:ok, new(req_id)}
  end

  def decode(req_id, subtopic) when is_integer(subtopic) do
    {:ok, new(req_id)}
  end
  def decode(_, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Read.Clock.Now do
  def encode(%@for{ req_id: req_id }) do
    read_message = Vex.Message.Read.new(req_id, Vex.Message.Read.Clock, @for)
    Vex.FrameEncoder.encode(read_message)
  end
end
