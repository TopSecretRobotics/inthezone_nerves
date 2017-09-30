defmodule Vex.PriorityMap do
  @table :vex_priority_map

  defstruct [
    key: nil,
    highest: nil,
    lowest: nil,
    monitors: %{}
  ]

  def new(key) do
    monitors =
      for [priority, pid] <- :ets.match(@table, {{key, :"$1"}, :"$2"}), into: %{} do
        {{:erlang.monitor(:process, pid), pid}, priority}
      end
    priority_map = %__MODULE__{ key: key, monitors: monitors }
    %{ priority_map | highest: get_highest(priority_map), lowest: get_lowest(priority_map) }
  end

  def delete(priority_map = %__MODULE__{ monitors: monitors }, priority, pid) do
    do_delete(Map.to_list(monitors), priority, pid, %{ priority_map | monitors: %{} })
  end

  @doc false
  defp do_delete([{{monitor_ref, pid}, priority} | rest], priority, pid, priority_map = %{ key: key, monitors: monitors }) do
    true = :ets.delete(@table, {key, priority})
    _ = :erlang.demonitor(monitor_ref, [:flush])
    monitors = Map.merge(monitors, :maps.from_list(rest))
    maybe_clear(%{ priority_map | monitors: monitors }, priority, pid)
  end
  defp do_delete([{k, v} | rest], priority, pid, priority_map = %{ monitors: monitors }) do
    monitors = Map.put(monitors, k, v)
    do_delete(rest, priority, pid, %{ priority_map | monitors: monitors })
  end
  defp do_delete([], _priority, _pid, priority_map) do
    priority_map
  end

  def down(priority_map = %__MODULE__{ key: key, monitors: monitors }, monitor_ref, pid) do
    case :maps.take({monitor_ref, pid}, monitors) do
      {priority, monitors} ->
        true = :ets.delete(@table, {key, priority})
        maybe_clear(%{ priority_map | monitors: monitors }, priority, pid)
      :error ->
        priority_map
    end
  end

  def highest(%__MODULE__{ highest: {_, pid} }) do
    {:ok, pid}
  end
  def highest(%__MODULE__{}) do
    :error
  end

  def lowest(%__MODULE__{ lowest: {_, pid} }) do
    {:ok, pid}
  end
  def lowest(%__MODULE__{}) do
    :error
  end

  def up(priority_map = %__MODULE__{ key: key, monitors: monitors }, priority, pid) do
    if :ets.insert_new(@table, {{key, priority}, pid}) do
      monitor_ref = :erlang.monitor(:process, pid)
      monitors = Map.put(monitors, {monitor_ref, pid}, priority)
      maybe_store(%{ priority_map | monitors: monitors }, priority, pid)
    else
      priority_map
    end
  end

  def to_list(%__MODULE__{ monitors: monitors }) do
    pids =
      for {{_, pid}, priority} <- monitors, into: [] do
        {priority, pid}
      end
    :lists.sort(pids)
  end

  @doc false
  defp get_highest(%__MODULE__{ monitors: monitors }) do
    get_highest(Map.to_list(monitors), nil)
  end

  @doc false
  defp get_highest([{{_, pid}, priority} | rest], nil) do
    get_highest(rest, {priority, pid})
  end
  defp get_highest([{{_, pid}, priority} | rest], {old_priority, _}) when old_priority < priority do
    get_highest(rest, {priority, pid})
  end
  defp get_highest([_ | rest], acc) do
    get_highest(rest, acc)
  end
  defp get_highest([], acc) do
    acc
  end

  @doc false
  defp get_lowest(%__MODULE__{ monitors: monitors }) do
    get_lowest(Map.to_list(monitors), nil)
  end

  @doc false
  defp get_lowest([{{_, pid}, priority} | rest], nil) do
    get_lowest(rest, {priority, pid})
  end
  defp get_lowest([{{_, pid}, priority} | rest], {old_priority, _}) when old_priority > priority do
    get_lowest(rest, {priority, pid})
  end
  defp get_lowest([_ | rest], acc) do
    get_lowest(rest, acc)
  end
  defp get_lowest([], acc) do
    acc
  end

  @doc false
  defp maybe_clear(priority_map = %__MODULE__{}, priority, pid) do
    priority_map
    |> maybe_clear_highest(priority, pid)
    |> maybe_clear_lowest(priority, pid)
  end

  @doc false
  defp maybe_clear_highest(priority_map = %__MODULE__{ highest: {priority, pid} }, priority, pid) do
    %{ priority_map | highest: get_highest(priority_map) }
  end
  defp maybe_clear_highest(priority_map, _, _) do
    priority_map
  end

  @doc false
  defp maybe_clear_lowest(priority_map = %__MODULE__{ lowest: {priority, pid} }, priority, pid) do
    %{ priority_map | lowest: get_lowest(priority_map) }
  end
  defp maybe_clear_lowest(priority_map, _, _) do
    priority_map
  end

  @doc false
  defp maybe_store(priority_map = %__MODULE__{}, priority, pid) do
    priority_map
    |> maybe_store_highest(priority, pid)
    |> maybe_store_lowest(priority, pid)
  end

  @doc false
  defp maybe_store_highest(priority_map = %__MODULE__{ highest: nil }, priority, pid) do
    %{ priority_map | highest: {priority, pid} }
  end
  defp maybe_store_highest(priority_map = %__MODULE__{ highest: {old_priority, _} }, priority, pid) when old_priority < priority do
    %{ priority_map | highest: {priority, pid} }
  end
  defp maybe_store_highest(priority_map, _, _) do
    priority_map
  end

  @doc false
  defp maybe_store_lowest(priority_map = %__MODULE__{ lowest: nil }, priority, pid) do
    %{ priority_map | lowest: {priority, pid} }
  end
  defp maybe_store_lowest(priority_map = %__MODULE__{ lowest: {old_priority, _} }, priority, pid) when old_priority > priority do
    %{ priority_map | lowest: {priority, pid} }
  end
  defp maybe_store_lowest(priority_map, _, _) do
    priority_map
  end
end
