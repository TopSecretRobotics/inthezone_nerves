defmodule Vex.Message.Write.Motor.All do

  defstruct [
    req_id: nil,
    value: nil
  ]

  def new(req_id, value) when is_list(value) do
    %__MODULE__{
      req_id: req_id,
      value: value
    }
  end
  def new(req_id, motors) when is_map(motors) do
    motors =
      for {index, value} when is_integer(index) and is_integer(value) <- motors, into: [] do
        {index, value}
      end
    motors = :lists.sort(motors)
    new(req_id, motors)
  end

  def cast(req_id, _subtopic, value) do
    {:ok, new(req_id, value)}
  end

  def decode(req_id, subtopic, value) when is_binary(value) and is_integer(subtopic) do
    with {:ok, value} <- decode_value(value, []) do
      {:ok, new(req_id, value)}
    end
  end
  def decode(_, _, _) do
    :error
  end

  @doc false
  defp decode_value(<<
    index :: signed-big-integer-unit(1)-size(8),
    value :: signed-big-integer-unit(1)-size(8),
    rest :: binary()
  >>, acc) do
    decode_value(rest, [{index, value} | acc])
  end
  defp decode_value(<<>>, acc) do
    {:ok, :lists.reverse(acc)}
  end
  defp decode_value(_, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Write.Motor.All do
  def encode(%@for{ req_id: req_id, value: motors }) do
    payload =
      for {index, value} when is_integer(index) and is_integer(value) <- motors, into: <<>> do
        <<
          index :: signed-big-integer-unit(1)-size(8),
          value :: signed-big-integer-unit(1)-size(8)
        >>
      end
    write_message = Vex.Message.Write.new(req_id, Vex.Message.Write.Motor, @for, payload)
    Vex.FrameEncoder.encode(write_message)
  end
end
