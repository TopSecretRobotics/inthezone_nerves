defmodule UiGraph.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :classic
  use UiGraph.Event.Notation
  alias __MODULE__, as: Schema

  # import_types Schema.Types
  import_types Schema.Config
  import_types Schema.Drive
  import_types Schema.Event
  import_types Schema.Motor
  import_types Schema.Robot
  import_types Schema.VCR

  query do
    import_fields :config_queries
    import_fields :drive_queries
    import_fields :event_queries
    import_fields :motor_queries
    import_fields :robot_queries
    import_fields :vcr_queries
    node field do
      resolve &Schema.node_field/3
    end
  end

  mutation do
    import_fields :motor_mutations
    import_fields :vcr_mutations
  end

  subscription do
    import_fields :event_subscriptions
    import_fields :motor_subscriptions
    import_fields :robot_subscriptions
    import_fields :vcr_subscriptions
  end

  node interface do
    resolve_type &Schema.node_interface/2
  end

  event interface do
    resolve_type &Schema.event_interface/2
  end

  def node_field(parent, attrs, info) do
    case attrs do
      %{ type: :cassette, id: id } ->
        Schema.VCR.node(parent, id, info)
      %{ type: :drive, id: id } ->
        Schema.Drive.node(parent, id, info)
      %{ type: :motor, id: id } ->
        Schema.Motor.node(parent, id, info)
      _ ->
        {:error, "bad node id"}
    end
  end

  def node_interface(type, _info) do
    case type do
      %Ui.Data.Cassette{} ->
        :cassette
      %Ui.Data.Drive{} ->
        :drive
      %Ui.Data.Motor{} ->
        :motor
      _ ->
        nil
    end
  end

  def event_interface(type, _info) do
    case type do
      %Ui.Events.Status{} ->
        :event_status
      %Ui.Events.Frame{} ->
        :event_frame
      %Ui.Events.Ping{} ->
        :event_ping
      %Ui.Events.Pong{} ->
        :event_pong
      %Ui.Events.Info{} ->
        :event_info
      %Ui.Events.Data{} ->
        :event_data
      %Ui.Events.Read{} ->
        :event_read
      %Ui.Events.Write{} ->
        :event_write
      %Ui.Events.Subscribe{} ->
        :event_subscribe
      %Ui.Events.Unsubscribe{} ->
        :event_unsubscribe
    end
    # require IEx
    # IEx.pry()
    # raise "error"
    # case type do
      # %{ type: Didrik.Events.DealCreated } ->
      #   :deal_created_event
      # %{ type: Didrik.Events.DealUpdated } ->
      #   :deal_updated_event
      # %{ type: Didrik.Events.PersonCreated } ->
      #   :person_created_event
      # %{ type: Didrik.Events.PersonDealAssigned } ->
      #   :person_deal_assigned_event
      # %{ type: Didrik.Events.PersonUpdated } ->
      #   :person_updated_event
      # _ ->
      #   nil
    # end
  end

  # query do
  #   field :foo, :string do
  #     resolve fn (_, _, _) ->
  #       {:ok, "bar"}
  #     end
  #   end

  #   field :motor, type: :motor do
  #     arg :id, non_null(:integer)
  #     resolve &Schema.field_motor/3
  #   end

  #   field :motors, type: list_of(:motor) do
  #     resolve &Schema.field_motors/3
  #   end

  # end

  # def field_motor(_parent, %{ id: id }, _info) do
  #   with {:ok, id} <- maybe_cast_id(id),
  #        {:ok, %{ time: time, value: value }} <- Vex.read_motor(id) do
  #     motor = %{
  #       id: id,
  #       ticks: time,
  #       value: value
  #     }
  #     {:ok, motor}
  #   end
  # end

  # def field_motors(_parent, _args, _info) do
  #   with {:ok, result} <- Vex.read_motor_all() do
  #     motors =
  #       for {id, %{ time: time, value: value }} <- result, into: [] do
  #         %{
  #           id: id,
  #           ticks: time,
  #           value: value
  #         }
  #       end
  #     {:ok, motors}
  #   end
  # end

  # @doc false
  # defp maybe_cast_id(integer) when is_integer(integer) do
  #   {:ok, integer}
  # end
  # defp maybe_cast_id(string) when is_binary(string) do
  #   with {integer, _} when is_integer(integer) <- Integer.parse(string) do
  #     {:ok, integer}
  #   else _ ->
  #     {:error, "bad ID"}
  #   end
  # end
  # defp maybe_cast_id(_) do
  #   {:error, "bad ID"}
  # end

  # import_types Schema.Types
  # import_types Schema.Account
  # import_types Schema.Person
  # import_types Schema.Pipeline

  # query do
  #   import_fields :account_queries
  #   import_fields :deal_queries
  #   import_fields :person_queries
  #   import_fields :pipeline_queries
  #   node field do
  #     resolve &Schema.node_field/3
  #   end
  # end

  # mutation do
  #   import_fields :deal_mutations
  #   import_fields :person_mutations
  # end

  # subscription do
  #   import_fields :deal_subscriptions
  #   import_fields :person_subscriptions
  #   import_fields :pipeline_subscriptions
  # end

  # node interface do
  #   resolve_type &Schema.node_interface/2
  # end

  # event interface do
  #   resolve_type &Schema.event_interface/2
  # end

  # def node_field(parent, attrs, info) do
  #   case attrs do
  #     %{ type: :deal, id: id } ->
  #       Schema.Deal.node(parent, id, info)
  #     %{ type: :event, id: id } ->
  #       Schema.Event.node(parent, id, info)
  #     %{ type: :person, id: id } ->
  #       Schema.Person.node(parent, id, info)
  #     %{ type: :pipeline, id: id } ->
  #       Schema.Pipeline.node(parent, id, info)
  #     %{ type: :pipeline_stage, id: id } ->
  #       Schema.PipelineStage.node(parent, id, info)
  #   end
  # end

  # def node_interface(type, _info) do
  #   case type do
  #     %Data.Deal{} ->
  #       :deal
  #     %Data.Event{} ->
  #       :event
  #     %Didrik.EventStore.Event{} ->
  #       :event
  #     %Data.Person{} ->
  #       :person
  #     %Data.Pipeline{} ->
  #       :pipeline
  #     %Data.PipelineStage{} ->
  #       :pipeline_stage
  #     _ ->
  #       nil
  #   end
  # end

  # def event_interface(type, _info) do
  #   case type do
  #     %{ type: Didrik.Events.DealCreated } ->
  #       :deal_created_event
  #     %{ type: Didrik.Events.DealUpdated } ->
  #       :deal_updated_event
  #     %{ type: Didrik.Events.PersonCreated } ->
  #       :person_created_event
  #     %{ type: Didrik.Events.PersonDealAssigned } ->
  #       :person_deal_assigned_event
  #     %{ type: Didrik.Events.PersonUpdated } ->
  #       :person_updated_event
  #     _ ->
  #       nil
  #   end
  # end

end
