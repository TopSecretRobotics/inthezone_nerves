defmodule Ui.VCR.Record do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @events Vex.State.Events
  @target Vex.State

  def start_link(cassette_id) do
    via = {:via, Registry, {Ui.VCR.Registry, {:cassette, cassette_id}}}
    GenStateMachine.start_link(__MODULE__, [cassette_id], [name: via])
  end

  def stop(cassette_id) do
    via = {:via, Registry, {Ui.VCR.Registry, {:cassette, cassette_id}}}
    GenStateMachine.cast(via, :stop)
  end

  defmodule Data do
    defstruct [
      cassette_id: nil,
      events: []
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([cassette_id]) do
    data = %Data{
      cassette_id: cassette_id
    }
    {:ok, :unsubscribed, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, _old_state, :unsubscribed, _data) do
    actions = [{:state_timeout, 0, :record}]
    {:keep_state_and_data, actions}
  end
  def handle_event(:enter, _old_state, :recording, _data) do
    :keep_state_and_data
  end
  # State Timeout Events
  def handle_event(:state_timeout, :record, :unsubscribed, data) do
    case cassette_record(data) do
      :ok ->
        :ok = @events.subscribe_motors()
        {:next_state, :recording, data}
      :error ->
        {:stop, :normal}
    end
  end
  # Cast Events
  def handle_event(:cast, :stop, :recording, data) do
    :ok = cassette_stop(data)
    {:stop, :normal}
  end
  def handle_event(:cast, :stop, _state, _data) do
    {:stop, :normal}
  end
  # Info Events
  def handle_event(:info, {@target, {:motor_state, ticks, values}}, :recording, data = %Data{ events: events }) do
    event = {ticks, values}
    events =
      case events do
        [^event | _] ->
          events
        _ ->
          [event | events]
      end
    data = %{ data | events: events }
    {:keep_state, data}
  end

  @doc false
  defp cassette_record(%Data{ cassette_id: cassette_id }) do
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
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, cassette, [
            observe_cassette: to_string(cassette.id)
          ])
          :ok
        _ ->
          :error
      end
    else
      :error
    end
  end

  @doc false
  defp cassette_stop(%Data{ cassette_id: cassette_id, events: events }) do
    data = :erlang.term_to_binary(:lists.reverse(events))
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      changeset = Ui.Data.Cassette.changeset(cassette, %{
        pid: nil,
        data: data,
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
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, cassette, [
            observe_cassette: to_string(cassette.id)
          ])
          :ok
        _ ->
          :ok
      end
    else
      :ok
    end
  end

end
