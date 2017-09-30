defmodule Vex.Buffer do

  @type buffer_data(type) :: :queue.queue(type) | list(type)
  @type buffer_data() :: buffer_data(term())
  @type buffer_drop() :: non_neg_integer()
  @type buffer_size() :: non_neg_integer()
  @type buffer_max() :: pos_integer()
  @type buffer_type() :: :keep_old | :queue | :stack

  @type t(type) :: %__MODULE__{
    type: buffer_type(),
    max: buffer_max(),
    size: buffer_size(),
    drop: buffer_drop(),
    data: buffer_data(type)
  }

  @type t() :: t(term())

  defstruct [
    type: nil,
    max: nil,
    size: 0,
    drop: 0,
    data: nil
  ]

  defmodule Flush do
    @type t(type) :: %__MODULE__{
      out: [type],
      size: Vex.Buffer.buffer_size(),
      drop: Vex.Buffer.buffer_drop()
    }
    @type t() :: t(term())

    defstruct [
      out: nil,
      size: nil,
      drop: nil
    ]
  end

  alias __MODULE__.Flush, as: Flush

  @spec new(buffer_type(), buffer_max()) :: t()
  def new(type, size) when type in [:queue, :stack, :keep_old] and is_integer(size) and size > 0 do
    case type do
      :queue ->
        %__MODULE__{ type: :queue, max: size, data: :queue.new() }
      :stack ->
        %__MODULE__{ type: :stack, max: size, data: [] }
      :keep_old ->
        %__MODULE__{ type: :keep_old, max: size, data: :queue.new() }
    end
  end

  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{ size: 0 }) do
    true
  end
  def empty?(%__MODULE__{}) do
    false
  end

  @spec flush(t()) :: {:ok, Flush.t(), t()}
  def flush(buffer = %__MODULE__{ type: type, size: size, drop: drop, data: data }) do
    {messages, new_data} = flush(type, data, [])
    flush = %Flush{ out: messages, size: size, drop: drop }
    {:ok, flush, %{ buffer | size: 0, drop: 0, data: new_data }}
  end

  @spec full?(t()) :: boolean()
  def full?(%__MODULE__{ max: size, size: size }) do
    true
  end
  def full?(%__MODULE__{}) do
    false
  end

  @spec input(t(), term()) :: {:ok, t()} | :error
  def input(%__MODULE__{ max: size, size: size }, _item) do
    :error
  end
  def input(buffer = %__MODULE__{}, item) do
    {:ok, input!(buffer, item)}
  end

  @spec input!(t(), term()) :: t()
  def input!(buffer = %__MODULE__{ type: type, max: size, size: size, drop: drop, data: data }, item) do
    %{ buffer | drop: drop + 1, data: input_drop(type, item, size, data) }
  end
  def input!(buffer = %__MODULE__{ type: type, size: size, data: data }, item) do
    %{ buffer | size: size + 1, data: input(type, item, data) }
  end

  @spec output(t()) :: {:ok, term(), t()} | :error
  def output(buffer = %__MODULE__{ type: type, size: size, data: data }) do
    case output(type, data) do
      {:empty, ^data} ->
        :error
      {{:value, item}, new_data} ->
        {:ok, item, %{ buffer | size: size - 1, data: new_data }}
    end
  end

  @spec resize(t(), buffer_max()) :: t()
  def resize(buffer = %__MODULE__{ max: max }, new_max) when max <= new_max do
    %{ buffer | max: new_max }
  end
  def resize(buffer = %__MODULE__{ type: type, size: size, drop: drop, data: data }, new_max) when size > new_max do
    to_drop = size - new_max
    %{ buffer | size: new_max, max: new_max, drop: drop + to_drop, data: drop(type, to_drop, size, data) }
  end
  def resize(buffer = %__MODULE__{}, new_max) do
    %{ buffer | max: new_max }
  end

  @spec to_list(t()) :: [term()]
  def to_list(buffer = %__MODULE__{}) do
    {:ok, %Flush{ out: out }, _} = flush(buffer)
    out
  end

  @doc false
  defp drop(type, size, data) do
    drop(type, 1, size, data)
  end

  @doc false
  defp drop(_, 0, _size, data) do
    data
  end
  defp drop(:queue, 1, _size, queue) do
    :queue.drop(queue)
  end
  defp drop(:stack, 1, _size, [_ | tail]) do
    tail
  end
  defp drop(:keep_old, 1, _size, queue) do
    :queue.drop_r(queue)
  end
  defp drop(:queue, n, size, queue) when size > n do
    :erlang.element(2, :queue.split(n, queue))
  end
  defp drop(:queue, _n, _size, _queue) do
    :queue.new()
  end
  defp drop(:stack, n, size, stack) when size > n do
    :lists.nthtail(n, stack)
  end
  defp drop(:stack, _n, _size, _stack) do
    []
  end
  defp drop(:keep_old, n, size, queue) when size > n do
    :erlang.element(1, :queue.split(n, queue))
  end
  defp drop(:keep_old, _n, _size, _queue) do
    :queue.new()
  end

  @doc false
  defp flush(type, data, messages) do
    case output(type, data) do
      {:empty, new_data} ->
        {:lists.reverse(messages), new_data}
      {{:value, message}, new_data} ->
        flush(type, new_data, [message | messages])
    end
  end

  @doc false
  defp input(:queue, message, queue) do
    :queue.in(message, queue)
  end
  defp input(:stack, message, stack) do
    [message | stack]
  end
  defp input(:keep_old, message, queue) do
    :queue.in(message, queue)
  end

  @doc false
  defp input_drop(:keep_old, _item, _size, data) do
    data
  end
  defp input_drop(type, item, size, data) do
    input(type, item, drop(type, size, data))
  end

  @doc false
  defp output(:queue, queue) do
    :queue.out(queue)
  end
  defp output(:stack, []) do
    {:empty, []}
  end
  defp output(:stack, [head | tail]) do
    {{:value, head}, tail}
  end
  defp output(:keep_old, queue) do
    :queue.out(queue)
  end

end

defimpl Enumerable, for: Vex.Buffer do
  def count(%@for{ size: size }) do
    {:ok, size}
  end

  def member?(buffer = %@for{}, element) do
    entries = @for.to_list(buffer)
    {:ok, Enum.member?(entries, element)}
  end

  def reduce(buffer = %@for{}, acc, fun) do
    entries = @for.to_list(buffer)
    reduce_list(entries, acc, fun)
  end

  @doc false
  defp reduce_list(_,       {:halt, acc}, _fun),   do: {:halted, acc}
  defp reduce_list(list,    {:suspend, acc}, fun), do: {:suspended, acc, &reduce_list(list, &1, fun)}
  defp reduce_list([],      {:cont, acc}, _fun),   do: {:done, acc}
  defp reduce_list([h | t], {:cont, acc}, fun),    do: reduce_list(t, fun.(h, acc), fun)
end

defimpl Enumerable, for: Vex.Buffer.Flush do
  def count(%@for{ size: size }) do
    {:ok, size}
  end

  def member?(%@for{ out: entries }, element) do
    {:ok, Enum.member?(entries, element)}
  end

  def reduce(%@for{ out: entries }, acc, fun) do
    reduce_list(entries, acc, fun)
  end

  @doc false
  defp reduce_list(_,       {:halt, acc}, _fun),   do: {:halted, acc}
  defp reduce_list(list,    {:suspend, acc}, fun), do: {:suspended, acc, &reduce_list(list, &1, fun)}
  defp reduce_list([],      {:cont, acc}, _fun),   do: {:done, acc}
  defp reduce_list([h | t], {:cont, acc}, fun),    do: reduce_list(t, fun.(h, acc), fun)
end
