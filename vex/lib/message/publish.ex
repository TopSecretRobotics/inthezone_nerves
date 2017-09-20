defmodule Vex.Message.PUBLISH do
  defstruct [
    op: nil,
    req_id: nil,
    type: nil,
    topic: nil,
    len: nil,
    value: nil
  ]
end

defimpl Vex.MessageEncoder, for: Vex.Message.PUBLISH do
  def encode(%@for{ op: op, req_id: req_id, type: type, topic: topic, len: len, value: value }) when is_integer(op) and is_integer(req_id) and is_integer(type) and is_integer(topic) and is_integer(len) and is_binary(value) do
    encoded = << op, req_id :: unsigned-big-integer-unit(1)-size(16), type, topic, len, value :: binary-size(len) >>
    {:ok, encoded}
  end
  def encode(_) do
    :error
  end
end