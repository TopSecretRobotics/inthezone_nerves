defmodule Vex.MotorState do

  # defmodule Entry do
  #   @type t() :: %__MODULE__{
  #     ticks: non_neg_integer(),
  #     value: [{integer(), integer()}]
  #   }

  #   defstruct [
  #     ticks: nil,
  #     value: []
  #   ]
  # end

  # alias __MODULE__.Entry, as: Entry

  @type entry() :: {non_neg_integer(), [{integer(), integer()}]}

  @type t() :: %__MODULE__{
    current: entry(),
    entries: [entry()]
  }

  defstruct [
    current: nil,
    entries: []
  ]

  def new() do
    %__MODULE__{}
  end

  def add(motor_state = %__MODULE__{ current: nil, entries: [] }, ticks, value) when is_integer(ticks) and ticks >= 0 and is_list(value) do
    entry = {ticks, value}
    motor_state = %{ motor_state | current: entry, entries: [entry] }
    motor_state
  end
  def add(motor_state = %__MODULE__{ current: {_, old_value}, entries: entries }, ticks, new_value) when is_integer(ticks) and ticks >= 0 and is_list(new_value) and length(old_value) == length(new_value) do
    case diff(old_value, new_value, [], []) do
      {true, current, diff} ->
        motor_state = %{ motor_state | current: {ticks, current}, entries: [{ticks, diff} | entries] }
        motor_state
      false ->
        motor_state = %{ motor_state | current: {ticks, old_value} }
        motor_state
    end
  end

  def fill(%__MODULE__{ current: nil }, value) when is_list(value) do
    value
  end
  def fill(%__MODULE__{ current: {_, a} }, b) when is_list(b) do
    make_fill(a, b, [])
  end

  def size(%__MODULE__{ current: {_, value} }) do
    length(value)
  end
  def size(%__MODULE__{ current: nil }) do
    0
  end

  def ticks(%__MODULE__{ current: {ticks, _} }) do
    ticks
  end
  def ticks(%__MODULE__{ current: nil }) do
    nil
  end

  def to_list(%__MODULE__{ current: nil, entries: [] }) do
    []
  end
  def to_list(%__MODULE__{ entries: entries }) do
    [head = {_, value} | tail] = :lists.reverse(entries)
    make_list(tail, value, [head])
  end

  def value(%__MODULE__{ current: {_, value} }) do
    value
  end
  def value(%__MODULE__{ current: nil }) do
    []
  end

  @doc false
  defp diff([{index, value} | old], [{index, value} | new], current, diff) do
    diff(old, new, [{index, value} | current], diff)
  end
  defp diff([{index, _old_value} | old], [{index, new_value} | new], current, diff) do
    diff(old, new, [{index, new_value} | current], [{index, new_value} | diff])
  end
  defp diff([], [], _current, []) do
    false
  end
  defp diff([], [], current, diff) do
    {true, :lists.reverse(current), :lists.reverse(diff)}
  end

  @doc false
  defp make_fill([{index, _} | a], [{index, value} | b], acc) do
    make_fill(a, b, [{index, value} | acc])
  end
  defp make_fill([{index, value} | a], b, acc) do
    make_fill(a, b, [{index, value} | acc])
  end
  defp make_fill([], [], acc) do
    :lists.reverse(acc)
  end

  @doc false
  defp make_list([{ticks, new} | rest], old, acc) do
    value = keymerge(old, new, [])
    make_list(rest, value, [{ticks, value} | acc])
  end
  defp make_list([], _old, acc) do
    :lists.reverse(acc)
  end

  @doc false
  defp keymerge([{index, _old_value} | old], [{index, new_value} | new], acc) do
    keymerge(old, new, [{index, new_value} | acc])
  end
  defp keymerge([{index, value} | old], new, acc) do
    keymerge(old, new, [{index, value} | acc])
  end
  defp keymerge([], [], acc) do
    :lists.reverse(acc)
  end

end