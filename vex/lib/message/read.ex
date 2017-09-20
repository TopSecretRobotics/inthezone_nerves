defmodule Vex.Message.READ do
  defstruct [
    op: nil,
    req_id: nil,
    type: nil,
    topic: nil
  ]
end

defimpl Vex.MessageEncoder, for: Vex.Message.READ do
  def encode(%@for{ op: op, req_id: req_id, type: type, topic: topic }) when is_integer(op) and is_integer(req_id) and is_integer(type) and is_integer(topic) do
    encoded = << op, req_id :: unsigned-big-integer-unit(1)-size(16), type, topic >>
    {:ok, encoded}
  end
  def encode(_) do
    :error
  end
end