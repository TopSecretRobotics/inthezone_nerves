defmodule Vex.Frame.PONG do

  @type t() :: %__MODULE__{
    seq_id: Vex.Stdint.uint8_t()
  }

  defstruct [
    seq_id: nil
  ]

  def new(seq_id) do
    Vex.Frame.pong(seq_id)
  end

  def decode(<< seq_id >>) do
    {:ok, new(seq_id)}
  end
  def decode(_) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Frame.PONG do
  def encode(%@for{ seq_id: seq_id }) do
    op = Vex.Frame.type_to_op!(@for)
    <<
      op,
      seq_id
    >>
  end
end

defimpl OJSON.Encoder, for: Vex.Frame.PONG do
  def encode(%@for{ seq_id: seq_id }, options) do
    op = Vex.Frame.type_to_op!(@for)
    map = %{
      op: op,
      seq_id: seq_id
    }
    OJSON.Encoder.encode(["PONG", map], options)
  end
end
