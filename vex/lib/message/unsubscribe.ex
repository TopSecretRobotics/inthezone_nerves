defmodule Vex.Message.UNSUBSCRIBE do
  defstruct [
    op: nil,
    req_id: nil
  ]
end

defimpl Vex.MessageEncoder, for: Vex.Message.UNSUBSCRIBE do
  def encode(%@for{ op: op, req_id: req_id }) when is_integer(op) and is_integer(req_id) do
    encoded = << op, req_id :: unsigned-big-integer-unit(1)-size(16) >>
    {:ok, encoded}
  end
  def encode(_) do
    :error
  end
end