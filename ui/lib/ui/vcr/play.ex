defmodule Ui.VCR.Play do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  def start_link(cassette_id) do
    via = {:via, Registry, {Ui.VCR.Registry, :play}}
    GenStateMachine.start_link(__MODULE__, [cassette_id], [name: via])
  end

  def stop(_cassette_id) do
    via = {:via, Registry, {Ui.VCR.Registry, :play}}
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
    {:ok, :paused, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, _old_state, :paused, _data) do
    actions = [{:state_timeout, 0, :play}]
    {:keep_state_and_data, actions}
  end
  def handle_event(:enter, _old_state, :playing, _data) do
    actions = [{:state_timeout, 0, :tick}]
    {:keep_state_and_data, actions}
  end
  # State Timeout Events
  def handle_event(:state_timeout, :play, :paused, data) do
    case cassette_play(data) do
      {:ok, events} ->
        data = %{ data | events: events }
        {:next_state, :playing, data}
      :error ->
        {:stop, :normal}
    end
  end
  def handle_event(:state_timeout, :tick, :playing, data) do
    case cassette_tick(data) do
      {:ok, duration, events} ->
        data = %{ data | events: events }
        require Logger
        Logger.info("")
        actions = [{:state_timeout, duration, :tick}]
        {:keep_state, data, actions}
      :error ->
        :ok = cassette_stop(data)
        {:stop, :normal}
    end
  end
  # Cast Events
  def handle_event(:cast, :stop, :playing, data) do
    motors =
      for index <- 0..9, into: [] do
        {index, 0}
      end
    :ok = Vex.RPC.write(:motor, :all, motors)
    :ok = cassette_stop(data)
    {:stop, :normal}
  end
  def handle_event(:cast, :stop, _state, _data) do
    {:stop, :normal}
  end

  @doc false
  defp cassette_play(%Data{ cassette_id: cassette_id }) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    case cassette do
      %Ui.Data.Cassette{ blank: false, pid: nil, play_at: nil, start_at: start_at, stop_at: stop_at, data: data } when start_at != nil and stop_at != nil and is_binary(data) ->
        events =
          try do
            :erlang.binary_to_term(data)
          catch _, _ ->
            []
          end
        case events do
          _ when is_list(events) ->
            events = cassette_events(events, nil, nil, [])
            changeset = Ui.Data.Cassette.changeset(cassette, %{
              pid: :erlang.term_to_binary(:erlang.self()),
              play_at: DateTime.utc_now()
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
                {:ok, events}
              _ ->
                :error
            end
          _ ->
            :error
        end
      _ ->
        :error
    end
  end

  @doc false
  defp cassette_events([{ticks, motors} | rest], nil, second, acc) do
    event = {ticks - ticks, motors}
    cassette_events(rest, ticks, second, [event | acc])
  end
  defp cassette_events([{ticks, motors} | rest], first, nil, acc) do
    event = {ticks - first, motors}
    cassette_events(rest, first, ticks, [event | acc])
  end
  defp cassette_events([{ticks, motors} | rest], first, second, acc) do
    event = {ticks - second, motors}
    cassette_events(rest, first, second, [event | acc])
  end
  defp cassette_events([], _first, _second, acc) do
    :lists.reverse(acc)
  end

  @doc false
  defp cassette_tick(%Data{ events: events }) do
    case events do
      [] ->
        motors =
          for index <- 0..9, into: [] do
            {index, 0}
          end
        :ok = Vex.RPC.write(:motor, :all, motors)
        :error
      [{ticks, motors} | [{next_ticks, _} | _] = next_events] ->
        duration = next_ticks - ticks
        duration =
          if duration <= 25 do
            25
          else
            duration
          end
        :ok = Vex.RPC.write(:motor, :all, motors)
        {:ok, duration, next_events}
      [{_ticks, motors}] ->
        :ok = Vex.RPC.write(:motor, :all, motors)
        {:ok, 25, []}
    end
  end

  @doc false
  defp cassette_stop(%Data{ cassette_id: cassette_id }) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      changeset = Ui.Data.Cassette.changeset(cassette, %{
        pid: nil,
        play_at: nil
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
