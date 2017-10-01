defmodule UiGraph.Schema.Cassette do
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
            events = :erlang.binary_to_term(data)
            motor_state =
              for {ticks, motors} <- events, into: [] do
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
    field :play_at, :string
    field :start_at, :string
    field :stop_at, :string
    field :inserted_at, :string
    field :updated_at, :string
    field :runtime, :integer do
      resolve fn (parent, _args, _info) ->
        if parent do
          with {:ok, runtime} <- Ui.VCR.runtime(parent.id) do
            {:ok, runtime}
          else _ ->
            {:ok, nil}
          end
        else
          {:ok, nil}
        end
      end
    end
  end

  object :cassette_queries do
    field :cassettes, type: list_of(:cassette) do
      resolve &Schema.Cassette.list/3
    end
  end

  object :cassette_mutations do
    payload field :update_cassette do
      input do
        field :id, non_null(:id)
        field :name, :string
      end

      output do
        field :cassette, :cassette
      end

      resolve parsing_node_ids(&Schema.Cassette.update/2, id: :cassette)
    end

    field :cassette_play, type: :boolean do
      arg :id, non_null(:id)
      resolve parsing_node_ids(&Schema.Cassette.play/2, id: :cassette)
    end

    field :cassette_record, type: :boolean do
      arg :id, non_null(:id)
      resolve parsing_node_ids(&Schema.Cassette.record/2, id: :cassette)
    end

    field :cassette_stop, type: :boolean do
      arg :id, non_null(:id)
      resolve parsing_node_ids(&Schema.Cassette.stop/2, id: :cassette)
    end

    field :cassette_erase, type: :boolean do
      arg :id, non_null(:id)
      resolve parsing_node_ids(&Schema.Cassette.erase/2, id: :cassette)
    end
  end

  object :cassette_subscriptions do
    field :observe_cassettes, type: list_of(:cassette) do
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
    end

    field :observe_cassette, type: list_of(:cassette) do
      arg :id, non_null(:id)
      config fn (%{ id: cassette_id }, _info) ->
        with {:ok, %{ type: :cassette, id: cassette_id }} <- Absinthe.Relay.Node.from_global_id(cassette_id, Schema) do
          {:ok, topic: cassette_id}
        else _ ->
          {:error, "bad id"}
        end
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
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, cassette, [
            observe_cassette: to_string(cassette.id)
          ])
          {:ok, %{ cassette: cassette }}
        error ->
          error
      end
    else
      {:error, "cassette not found"}
    end
  end

  def play(%{ id: cassette_id }, _info) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      with {:ok, _} <- Ui.VCR.play(cassette.id) do
        {:ok, true}
      else _ ->
        {:ok, false}
      end
    else
      {:error, "cassette not found"}
    end
  end

  def record(%{ id: cassette_id }, _info) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      with {:ok, _} <- Ui.VCR.record(cassette.id) do
        {:ok, true}
      else _ ->
        {:ok, false}
      end
    else
      {:error, "cassette not found"}
    end
  end

  def stop(%{ id: cassette_id }, _info) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      with {:ok, _} <- Ui.VCR.stop(cassette.id) do
        {:ok, true}
      else _ ->
        {:ok, false}
      end
    else
      {:error, "cassette not found"}
    end
  end

  def erase(%{ id: cassette_id }, _info) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      with {:ok, _} <- Ui.VCR.erase(cassette.id) do
        {:ok, true}
      else _ ->
        {:ok, false}
      end
    else
      {:error, "cassette not found"}
    end
  end

end
