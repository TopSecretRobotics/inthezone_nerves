defmodule Vex.Message.Read.Pubsub.Item do

  defstruct [
    req_id: nil,
    index: nil
  ]

  def new(req_id, index) when is_integer(index) do
    %__MODULE__{
      req_id: req_id,
      index: index
    }
  end

  def cast(req_id, subtopic) do
    {:ok, new(req_id, subtopic)}
  end

  def decode(req_id, subtopic) when is_integer(subtopic) do
    {:ok, new(req_id, subtopic)}
  end
  def decode(_, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Read.Pubsub.Item do
  def encode(%@for{ req_id: req_id, index: index }) do
    read_message = Vex.Message.Read.new(req_id, Vex.Message.Read.Pubsub, index)
    Vex.FrameEncoder.encode(read_message)
  end
end
