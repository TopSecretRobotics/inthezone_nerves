defmodule Vex.Message.Data.Motor.All do

  defstruct [
    req_id: nil,
    flag: nil,
    ticks: nil,
    value: nil
  ]

  def new(req_id, flag, ticks, value) when is_list(value) do
    %__MODULE__{
      req_id: req_id,
      flag: flag,
      ticks: ticks,
      value: value
    }
  end
  def new(req_id, flag, ticks, motors) when is_map(motors) do
    motors =
      for {index, value} when is_integer(index) and is_integer(value) <- motors, into: [] do
        {index, value}
      end
    motors = :lists.sort(motors)
    new(req_id, flag, ticks, motors)
  end

  def decode(req_id, subtopic, flag, ticks, value) when is_integer(subtopic) and is_binary(value) do
    with {:ok, value} <- decode_value(value, []) do
      {:ok, new(req_id, flag, ticks, value)}
    end
  end
  def decode(_, _, _, _, _) do
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

defimpl Vex.FrameEncoder, for: Vex.Message.Data.Motor.All do
  def encode(%@for{ req_id: req_id, flag: flag, ticks: ticks, value: motors }) do
    payload =
      for {index, value} when is_integer(index) and is_integer(value) <- motors, into: <<>> do
        <<
          index :: signed-big-integer-unit(1)-size(8),
          value :: signed-big-integer-unit(1)-size(8)
        >>
      end
    data_message = Vex.Message.Data.new(req_id, Vex.Message.Data.Motor, @for, flag, ticks, payload)
    Vex.FrameEncoder.encode(data_message)
  end
end
