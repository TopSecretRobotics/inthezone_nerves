defmodule Vex.Message.Data.Pubsub.List do

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
  def new(req_id, flag, ticks, subs) when is_map(subs) do
    subs =
      for {index, item = %Vex.Message.Data.Pubsub.Item{}} when is_integer(index) <- subs, into: [] do
        {index, %{ item | index: index }}
      end
    subs =
      for {_, item} <- :lists.sort(subs), into: [] do
        item
      end
    new(req_id, flag, ticks, subs)
  end

  def decode(req_id, subtopic, flag, ticks, <<>>) when is_integer(subtopic) do
    {:ok, new(req_id, flag, ticks, [])}
  end
  def decode(req_id, subtopic, flag, ticks, value) when is_integer(subtopic) when is_binary(value) do
    item = %Vex.Message.Data.Pubsub.Item{
      req_id: req_id,
      flag: flag,
      ticks: ticks
    }
    with {:ok, value} <- decode_value(value, item, []) do
      {:ok, new(req_id, flag, ticks, value)}
    end
  end
  def decode(_, _, _, _, _) do
    :error
  end

  @doc false
  defp decode_value(<<
    index,
    sub_id :: unsigned-big-integer-unit(1)-size(16),
    sub_topic :: unsigned-big-integer-unit(1)-size(8),
    sub_subtopic :: unsigned-big-integer-unit(1)-size(8),
    rest :: binary()
  >>, item, acc) do
    new_item = %{ item | index: index, sub_id: sub_id, sub_topic: sub_topic, sub_subtopic: sub_subtopic }
    decode_value(rest, item, [new_item | acc])
  end
  defp decode_value(<<>>, _item, acc) do
    {:ok, :lists.reverse(acc)}
  end
  defp decode_value(_, _, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Data.Pubsub.List do
  def encode(%@for{ req_id: req_id, flag: flag, ticks: ticks, value: value }) do
    payload =
      for %{ index: index, sub_id: sub_id, sub_topic: sub_topic, sub_subtopic: sub_subtopic } <- value, into: <<>> do
        <<
          index,
          sub_id :: unsigned-big-integer-unit(1)-size(16),
          sub_topic :: unsigned-big-integer-unit(1)-size(8),
          sub_subtopic :: unsigned-big-integer-unit(1)-size(8)
        >>
      end
    data_message = Vex.Message.Data.new(req_id, Vex.Message.Data.Pubsub, @for, flag, ticks, payload)
    Vex.FrameEncoder.encode(data_message)
  end
end
