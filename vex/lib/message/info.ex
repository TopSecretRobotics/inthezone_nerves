defmodule Vex.Message.INFO do
  defstruct [
    op: nil,
    len: nil,
    value: nil
  ]
end

defimpl Vex.MessageEncoder, for: Vex.Message.INFO do
  def encode(%@for{ op: op, len: len, value: value }) when is_integer(op) and is_integer(len) and is_binary(value) do
    encoded = << op, len, value :: binary-size(len) >>
    {:ok, encoded}
  end
  def encode(_) do
    :error
  end
end