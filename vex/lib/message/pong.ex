defmodule Vex.Message.PONG do
  defstruct [
    op: nil,
    seq_id: nil
  ]
end

defimpl Vex.MessageEncoder, for: Vex.Message.PONG do
  def encode(%@for{ op: op, seq_id: seq_id }) when is_integer(op) and is_integer(seq_id) do
    encoded = << op, seq_id >>
    {:ok, encoded}
  end
  def encode(_) do
    :error
  end
end