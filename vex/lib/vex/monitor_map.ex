defmodule Vex.MonitorMap do
  @table :vex_monitor_map

  defstruct [
    key: nil,
    monitors: %{}
  ]

  def new(key) do
    monitors =
      for [ref, pid] <- :ets.match(@table, {{key, :"$1"}, :"$2"}), into: %{} do
        {{:erlang.monitor(:process, pid), pid}, ref}
      end
    monitor_map = %__MODULE__{ key: key, monitors: monitors }
    monitor_map
  end

  def delete(monitor_map = %__MODULE__{ monitors: monitors }) do
    do_delete(Map.to_list(monitors), %{ monitor_map | monitors: %{} })
  end

  @doc false
  defp do_delete([{{monitor_ref, _pid}, ref} | rest], monitor_map = %{ key: key }) do
    true = :ets.delete(@table, {key, ref})
    _ = :erlang.demonitor(monitor_ref, [:flush])
    do_delete(rest, monitor_map)
  end
  defp do_delete([], monitor_map) do
    monitor_map
  end

  def delete_by_pid(monitor_map = %__MODULE__{ monitors: monitors }, pid) do
    do_delete_by_pid(Map.to_list(monitors), pid, %{ monitor_map | monitors: %{} })
  end

  @doc false
  defp do_delete_by_pid([{{monitor_ref, pid}, ref} | rest], pid, monitor_map = %{ key: key, monitors: monitors }) do
    true = :ets.delete(@table, {key, ref})
    _ = :erlang.demonitor(monitor_ref, [:flush])
    monitors = Map.merge(monitors, :maps.from_list(rest))
    do_delete_by_pid(rest, pid, %{ monitor_map | monitors: monitors })
  end
  defp do_delete_by_pid([{k, v} | rest], pid, monitor_map = %{ monitors: monitors }) do
    monitors = Map.put(monitors, k, v)
    do_delete_by_pid(rest, pid, %{ monitor_map | monitors: monitors })
  end
  defp do_delete_by_pid([], _pid, monitor_map) do
    monitor_map
  end

  def delete_by_ref(monitor_map = %__MODULE__{ monitors: monitors }, ref) do
    do_delete_by_ref(Map.to_list(monitors), ref, %{ monitor_map | monitors: %{} })
  end

  @doc false
  defp do_delete_by_ref([{{monitor_ref, _pid}, ref} | rest], ref, monitor_map = %{ key: key, monitors: monitors }) do
    true = :ets.delete(@table, {key, ref})
    _ = :erlang.demonitor(monitor_ref, [:flush])
    monitors = Map.merge(monitors, :maps.from_list(rest))
    do_delete_by_ref(rest, ref, %{ monitor_map | monitors: monitors })
  end
  defp do_delete_by_ref([{k, v} | rest], ref, monitor_map = %{ monitors: monitors }) do
    monitors = Map.put(monitors, k, v)
    do_delete_by_ref(rest, ref, %{ monitor_map | monitors: monitors })
  end
  defp do_delete_by_ref([], _ref, monitor_map) do
    monitor_map
  end

  def down(monitor_map = %__MODULE__{ key: key, monitors: monitors }, monitor_ref, pid) do
    case :maps.take({monitor_ref, pid}, monitors) do
      {ref, monitors} ->
        true = :ets.delete(@table, {key, ref})
        %{ monitor_map | monitors: monitors }
      :error ->
        monitor_map
    end
  end

  def up(monitor_map = %__MODULE__{ key: key, monitors: monitors }, ref, pid) do
    if :ets.insert_new(@table, {{key, ref}, pid}) do
      monitor_ref = :erlang.monitor(:process, pid)
      monitors = Map.put(monitors, {monitor_ref, pid}, ref)
      %{ monitor_map | monitors: monitors }
    else
      monitor_map
    end
  end

  def to_list(%__MODULE__{ monitors: monitors }) do
    pids =
      for {{_, pid}, ref} <- monitors, into: [] do
        {ref, pid}
      end
    :lists.sort(pids)
  end

end
