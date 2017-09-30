defmodule Ui.VCR.Record do
  use GenServer

  def start_link(cassette_id) do
    GenServer.start_link(__MODULE__, [cassette_id])
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  defmodule State do
    defstruct [
      cassette_id: nil,
      motors: nil,
      last: nil
    ]
  end

  @impl GenServer
  def init([cassette_id]) do
    :ok = Ui.Vex.Events.subscribe_frames()
    {:ok, true} = cassette_record(cassette_id)
    # cassette = Ui.Repo.get!(Ui.Data.Cassette, cassette_id)
    state = %State{
      cassette_id: cassette_id,
      motors: Vex.MotorState.new(),
      last: nil
    }
    {:ok, state}
  end

  @impl GenServer
  def handle_cast(:stop, state = %State{ cassette_id: cassette_id, motors: motors }) do
    blob = :erlang.term_to_binary(motors)
    cassette = Ui.Repo.get!(Ui.Data.Cassette, cassette_id)
    changeset = Ui.Data.Cassette.changeset(cassette, %{
      pid: nil,
      data: blob,
      stop_at: DateTime.utc_now()
    })
    Ecto.Multi.new()
    |> Ecto.Multi.update(:cassette, changeset)
    |> Ui.Repo.transaction()
    |> case do
      {:ok, %{ cassette: cassette }} ->
        :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, [cassette], [
          observe_cassettes: <<>>
        ])
        {:stop, :normal, state}
      _ ->
        {:stop, :normal, state}
    end
  end

  @impl GenServer
  def handle_info({:vex, :data, frame = %Vex.Message.Data.Motor.All{ ticks: ticks, value: value }}, state = %State{ motors: motors, last: last }) do
    cond do
      last == frame ->
        {:noreply, state}
      Vex.MotorState.size(motors) != length(value) or Vex.MotorState.ticks(motors) > ticks ->
        motors = Vex.MotorState.new()
        motors = Vex.MotorState.add(motors, ticks, value)
        # :ok = store(motors.current)
        state = %{ state | motors: motors, last: frame }
        {:noreply, state}
      true ->
        # old_value = Vex.MotorState.value(motors)
        motors = Vex.MotorState.add(motors, ticks, value)
        # new_value = Vex.MotorState.value(motors)
        state = %{ state | motors: motors, last: frame }
        {:noreply, state}
        # if old_value != new_value do
        #   if old_value == [] do
        #     :ok = store(motors.current)
        #   else
        #     [change | _] = motors.entries
        #     :ok = store(change)
        #   end
        #   {:noreply, state}
        # else
        #   {:noreply, state}
        # end
    end
  end

  @doc false
  defp cassette_record(cassette_id) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      changeset = Ui.Data.Cassette.changeset(cassette, %{
        blank: false,
        pid: :erlang.term_to_binary(:erlang.self()),
        data: nil,
        start_at: DateTime.utc_now(),
        stop_at: nil
      })
      Ecto.Multi.new()
      |> Ecto.Multi.update(:cassette, changeset)
      |> Ui.Repo.transaction()
      |> case do
        {:ok, %{ cassette: cassette }} ->
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, [cassette], [
            observe_cassettes: <<>>
          ])
          {:ok, true}
        error ->
          error
      end
    else
      {:error, "cassette not found"}
    end
  end

  # @doc false
  # defp store({ticks, motors}) when is_list(motors) and length(motors) > 0 do
  #   Ecto.Multi.new()
  #   |> motor_update("motor", ticks, motors)
  #   |> Ui.Repo.transaction()
  #   |> case do
  #     {:ok, data} ->
  #       motor_list =
  #         for {"motor_" <> _, motor} <- data, into: [] do
  #           {motor.id, motor}
  #         end
  #         |> Enum.sort()
  #       motor_list =
  #         for {_, motor} <- motor_list, into: [] do
  #           motor
  #         end
  #       if motor_list != [] do
  #         :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, motor_list, [
  #           observe_motors: <<>>
  #         ])
  #       end
  #       :ok
  #     _ ->
  #       :ok
  #   end
  # end
  # defp store(_) do
  #   :ok
  # end

  # @doc false
  # defp motor_update(multi, name, ticks, motors) do
  #   require Ecto.Query
  #   motor_ids =
  #     for {index, _} <- motors, into: [] do
  #       index
  #     end
  #   motor_query =
  #     Ecto.Query.from(m in Ui.Data.Motor,
  #       where: m.id in ^motor_ids)
  #   motor_cache =
  #     for motor = %Ui.Data.Motor{ id: id } <- Ui.Repo.all(motor_query), into: %{} do
  #       {id, motor}
  #     end
  #   motor_update_multi(multi, name, motor_cache, ticks, motors)
  # end

  # @doc false
  # defp motor_update_multi(multi, name, cache, ticks, [{index, value} | motors]) do
  #   motor = Map.fetch!(cache, index)
  #   changeset = Ui.Data.Motor.changeset(motor, %{ ticks: ticks, value: value })
  #   multi = Ecto.Multi.update(multi, "#{name}_#{index}", changeset)
  #   motor_update_multi(multi, name, cache, ticks, motors)
  # end
  # defp motor_update_multi(multi, _name, _cache, _ticks, []) do
  #   multi
  # end
end
