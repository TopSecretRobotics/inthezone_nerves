defmodule UiGraph.Schema.VCR do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  alias UiGraph.Schema

  object :motor_value do
    field :index, non_null(:integer)
    field :value, non_null(:integer)
  end

  object :motor_state do
    field :ticks, non_null(:integer)
    field :motors, type: list_of(:motor_value)
  end

  node object :cassette do
    field :name, non_null(:string)
    field :blank, non_null(:boolean)
    field :data, type: list_of(:motor_state) do
      resolve fn (parent, _args, _info) ->
        case parent do
          %{ data: nil } ->
            {:ok, nil}
          %{ data: data } ->
            motor_state = :erlang.binary_to_term(data)
            motor_state =
              for {ticks, motors} <- Vex.MotorState.to_list(motor_state), into: [] do
                motors =
                  for {index, value} <- motors, into: [] do
                    %{
                      index: index,
                      value: value
                    }
                  end
                %{
                  ticks: ticks,
                  motors: motors
                }
              end
            {:ok, motor_state}
        end
      end
    end
    field :start_at, :string
    field :stop_at, :string
    field :inserted_at, :string
    field :updated_at, :string
  end

  object :vcr_queries do
    field :cassettes, type: list_of(:cassette) do
      resolve &Schema.VCR.list/3
    end
  end

  object :vcr_mutations do
    payload field :update_cassette do
      input do
        field :id, non_null(:id)
        field :name, :string
      end

      output do
        field :cassette, :cassette
      end

      resolve parsing_node_ids(&Schema.VCR.update/2, id: :cassette)
    end

    field :vcr_record, type: :boolean do
      arg :id, non_null(:id)
      resolve parsing_node_ids(&Schema.VCR.record/2, id: :cassette)
    end

    field :vcr_stop, type: :boolean do
      arg :id, non_null(:id)
      resolve parsing_node_ids(&Schema.VCR.stop/2, id: :cassette)
    end

    field :vcr_erase, type: :boolean do
      arg :id, non_null(:id)
      resolve parsing_node_ids(&Schema.VCR.erase/2, id: :cassette)
    end
  end

  object :vcr_subscriptions do
    field :observe_cassettes, type: list_of(:cassette) do
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
    end
  end

  def list(_parent, _args, _info) do
    require Ecto.Query
    cassettes =
      Ecto.Query.from(c in Ui.Data.Cassette,
        order_by: [asc: c.id])
      |> Ui.Repo.all()
    {:ok, cassettes}
  end

  def node(_parent, cassette_id, _info) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    {:ok, cassette}
  end

  def update(args = %{ id: cassette_id }, _info) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      changeset = Ui.Data.Cassette.changeset(cassette, args)
      Ecto.Multi.new()
      |> Ecto.Multi.update(:cassette, changeset)
      |> Ui.Repo.transaction()
      |> case do
        {:ok, %{ cassette: cassette }} ->
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, [cassette], [
            observe_cassettes: <<>>
          ])
          {:ok, %{ cassette: cassette }}
        error ->
          error
      end
    else
      {:error, "cassette not found"}
    end
  end

  def record(%{ id: cassette_id }, _info) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      {:ok, _} = Ui.VCR.Record.start_link(cassette.id)
      {:ok, true}
    else
      {:error, "cassette not found"}
    end
    #   changeset = Ui.Data.Cassette.changeset(cassette, %{ blank: false, start_at: DateTime.utc_now() })
    #   Ecto.Multi.new()
    #   |> Ecto.Multi.update(:cassette, changeset)
    #   |> Ui.Repo.transaction()
    #   |> case do
    #     {:ok, %{ cassette: cassette }} ->
    #       :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, [cassette], [
    #         observe_cassettes: <<>>
    #       ])
    #       {:ok, true}
    #     error ->
    #       error
    #   end
    # else
    #   {:error, "cassette not found"}
    # end
  end

  def stop(%{ id: cassette_id }, _info) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      if cassette.pid do
        pid = :erlang.binary_to_term(cassette.pid)
        :ok = Ui.VCR.Record.stop(pid)
        {:ok, true}
      else
        {:ok, false}
      end
    #   changeset = Ui.Data.Cassette.changeset(cassette, %{ blank: false, stop_at: DateTime.utc_now() })
    #   Ecto.Multi.new()
    #   |> Ecto.Multi.update(:cassette, changeset)
    #   |> Ui.Repo.transaction()
    #   |> case do
    #     {:ok, %{ cassette: cassette }} ->
    #       :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, [cassette], [
    #         observe_cassettes: <<>>
    #       ])
    #       {:ok, true}
    #     error ->
    #       error
    #   end
    else
      {:error, "cassette not found"}
    end
  end

  def erase(%{ id: cassette_id }, _info) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      changeset = Ui.Data.Cassette.changeset(cassette, %{ blank: true, pid: nil, data: nil, start_at: nil, stop_at: nil })
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

  # def write_all_motors(%{ value: motors }, _info) when is_list(motors) do
  #   payload =
  #     for %{ index: index, value: value } when is_integer(index) and is_integer(value) <- motors, into: [] do
  #       {index, value}
  #     end
  #   if length(payload) == 0 do
  #     {:ok, false}
  #   else
  #     :ok = Vex.RPC.write(:motor, :all, payload)
  #     {:ok, true}
  #   end
  # end
  # def write_all_motors(_args, _info) do
  #   {:ok, false}
  # end

  # def reverse_all_motors(_args, _info) do
  #   require Ecto.Query
  #   motors =
  #     Ecto.Query.from(m in Ui.Data.Motor,
  #       order_by: [asc: m.id])
  #     |> Ui.Repo.all()
  #   payload =
  #     for %{ index: index, value: value } <- motors, into: [] do
  #       {index, value * -1}
  #     end
  #   :ok = Vex.RPC.write(:motor, :all, payload)
  #   {:ok, true}
  # end

  # def stop_all_motors(_args, _info) do
  #   payload =
  #     for index <- 0..9, into: [] do
  #       {index, 0}
  #     end
  #   :ok = Vex.RPC.write(:motor, :all, payload)
  #   {:ok, true}
  # end

end
