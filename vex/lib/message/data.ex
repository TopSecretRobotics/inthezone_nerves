defmodule Vex.Message.DATA do
  defstruct [
    op: nil,
    req_id: nil,
    flag: nil,
    len: nil,
    value: nil
  ]
end

defimpl Vex.MessageEncoder, for: Vex.Message.DATA do
  def encode(%@for{ op: op, req_id: req_id, flag: flag, len: len, value: value }) when is_integer(op) and is_integer(req_id) and is_integer(flag) and is_integer(len) and is_binary(value) do
    encoded = << op, req_id :: unsigned-big-integer-unit(1)-size(16), flag, len, value :: binary-size(len) >>
    {:ok, encoded}
  end
  def encode(_) do
    :error
  end
end