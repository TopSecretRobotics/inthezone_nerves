defmodule Ui.Vex.MotorState do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  defmodule State do
    defstruct [
      data: nil,
      last: nil
    ]
  end

  @impl GenServer
  def init([]) do
    :ok = Ui.Vex.Events.subscribe_frames()
    state = %State{
      data: Vex.MotorState.new(),
      last: nil
    }
    {:ok, state}
  end

  @impl GenServer
  def handle_info({:vex, :data, frame = %Vex.Message.Data.Motor.All{ ticks: ticks, value: value }}, state = %State{ data: data, last: last }) do
    cond do
      last == frame ->
        {:noreply, state}
      Vex.MotorState.size(data) != length(value) or Vex.MotorState.ticks(data) > ticks ->
        data = Vex.MotorState.new()
        data = Vex.MotorState.add(data, ticks, value)
        :ok = store(data.current)
        state = %{ state | data: data, last: frame }
        {:noreply, state}
      true ->
        old_value = Vex.MotorState.value(data)
        data = Vex.MotorState.add(data, ticks, value)
        new_value = Vex.MotorState.value(data)
        state = %{ state | data: data, last: frame }
        if old_value != new_value do
          if old_value == [] do
            :ok = store(data.current)
          else
            [change | _] = data.entries
            :ok = store(change)
          end
          {:noreply, state}
        else
          {:noreply, state}
        end
    end
  end

  @doc false
  defp store({ticks, motors}) when is_list(motors) and length(motors) > 0 do
    Ecto.Multi.new()
    |> motor_update("motor", ticks, motors)
    |> Ui.Repo.transaction()
    |> case do
      {:ok, data} ->
        motor_list =
          for {"motor_" <> _, motor} <- data, into: [] do
            {motor.id, motor}
          end
          |> Enum.sort()
        motor_list =
          for {_, motor} <- motor_list, into: [] do
            motor
          end
        if motor_list != [] do
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, motor_list, [
            observe_motors: <<>>
          ])
        end
        :ok
      _ ->
        :ok
    end
  end
  defp store(_) do
    :ok
  end

  @doc false
  defp motor_update(multi, name, ticks, motors) do
    require Ecto.Query
    motor_ids =
      for {index, _} <- motors, into: [] do
        index
      end
    motor_query =
      Ecto.Query.from(m in Ui.Data.Motor,
        where: m.id in ^motor_ids)
    motor_cache =
      for motor = %Ui.Data.Motor{ id: id } <- Ui.Repo.all(motor_query), into: %{} do
        {id, motor}
      end
    motor_update_multi(multi, name, motor_cache, ticks, motors)
  end

  @doc false
  defp motor_update_multi(multi, name, cache, ticks, [{index, value} | motors]) do
    motor = Map.fetch!(cache, index)
    changeset = Ui.Data.Motor.changeset(motor, %{ ticks: ticks, value: value })
    multi = Ecto.Multi.update(multi, "#{name}_#{index}", changeset)
    motor_update_multi(multi, name, cache, ticks, motors)
  end
  defp motor_update_multi(multi, _name, _cache, _ticks, []) do
    multi
  end
end