defmodule UiGraph.Schema.Motor do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  alias UiGraph.Schema

  node object :motor do
    field :index, non_null(:integer)
    field :ticks, non_null(:integer)
    field :value, non_null(:integer)
  end

  input_object :motor_command do
    field :index, non_null(:integer)
    field :value, non_null(:integer)
  end

  object :motor_queries do
    field :motors, type: list_of(:motor) do
      resolve &Schema.Motor.list/3
    end
  end

  object :motor_mutations do
    payload field :update_motor do
      input do
        field :id, non_null(:id)
        field :value, :integer
      end

      output do
        field :motor, :motor
      end

      resolve parsing_node_ids(&Schema.Motor.update/2, id: :motor)
    end

    field :write_all_motors, type: :boolean do
      arg :value, type: list_of(:motor_command)
      resolve &Schema.Motor.write_all_motors/2
    end

    field :reverse_all_motors, type: :boolean do
      resolve &Schema.Motor.reverse_all_motors/2
    end

    field :stop_all_motors, type: :boolean do
      resolve &Schema.Motor.stop_all_motors/2
    end
  end

  object :motor_subscriptions do
    field :observe_motors, type: list_of(:motor) do
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
    end
  end

  def list(_parent, _args, _info) do
    require Ecto.Query
    motors =
      Ecto.Query.from(m in Ui.Data.Motor,
        order_by: [asc: m.id])
      |> Ui.Repo.all()
    {:ok, motors}
  end

  def node(_parent, motor_id, _info) do
    motor = Ui.Repo.get(Ui.Data.Motor, motor_id)
    {:ok, motor}
  end

  def update(args = %{ id: motor_id }, _info) do
    motor = Ui.Repo.get(Ui.Data.Motor, motor_id)
    if motor do
      args =
        if args[:value] && is_integer(args[:value]) do
          value = args[:value]
          value =
            cond do
              value > 127 -> 127
              value < -127 -> -127
              true -> value
            end
          :ok = Vex.RPC.write(:motor, motor.index, value)
          Map.delete(args, :value)
        else
          args
        end
      changeset = Ui.Data.Motor.changeset(motor, args)
      Ecto.Multi.new()
      |> Ecto.Multi.update(:motor, changeset)
      |> Ui.Repo.transaction()
      |> case do
        {:ok, %{ motor: motor }} ->
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, [motor], [
            observe_motors: <<>>
          ])
          {:ok, %{ motor: motor }}
        error ->
          error
      end
    else
      {:error, "motor not found"}
    end
  end

  def write_all_motors(%{ value: motors }, _info) when is_list(motors) do
    payload =
      for %{ index: index, value: value } when is_integer(index) and is_integer(value) <- motors, into: [] do
        {index, value}
      end
    if length(payload) == 0 do
      {:ok, false}
    else
      :ok = Vex.RPC.write(:motor, :all, payload)
      {:ok, true}
    end
  end
  def write_all_motors(_args, _info) do
    {:ok, false}
  end

  def reverse_all_motors(_args, _info) do
    require Ecto.Query
    motors =
      Ecto.Query.from(m in Ui.Data.Motor,
        order_by: [asc: m.id])
      |> Ui.Repo.all()
    payload =
      for %{ index: index, value: value } <- motors, into: [] do
        {index, value * -1}
      end
    :ok = Vex.RPC.write(:motor, :all, payload)
    {:ok, true}
  end

  def stop_all_motors(_args, _info) do
    payload =
      for index <- 0..9, into: [] do
        {index, 0}
      end
    :ok = Vex.RPC.write(:motor, :all, payload)
    {:ok, true}
  end

end
