defmodule Ui.State.Cortex do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @events Vex.State.Events
  @target Vex.State

  def start_link() do
    GenStateMachine.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def read() do
    pid = :erlang.self()
    with :ok <- Vex.State.Autostart.subscribe(__MODULE__, pid) do
      reply = GenStateMachine.call(__MODULE__, :read)
      :ok = Vex.State.Autostart.unsubscribe(__MODULE__, pid)
      reply
    end
  end

  def observe() do
    pid = :erlang.self()
    Vex.State.Autostart.subscribe(__MODULE__, pid)
  end

  def subscribe(pid) do
    GenStateMachine.cast(__MODULE__, {:subscribe, pid})
  end

  def stop() do
    GenStateMachine.cast(__MODULE__, :stop)
  end

  defmodule Data do
    defstruct [
      calls: :queue.new(),
      record: nil
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    record = %Ui.Data.Cortex{
      backup_battery: 0,
      connected: false,
      main_battery: 0,
      ticks: 0
    }
    data = %Data{
      record: record
    }
    {:ok, :unsubscribed, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, _old_state, :unsubscribed, _data) do
    :ok = @events.subscribe_cortex()
    :keep_state_and_data
  end
  def handle_event(:enter, _old_state, :subscribed, data = %Data{ calls: calls, record: record }) do
    data = %{ data | calls: :queue.new() }
    actions = flush(calls, record, [])
    {:keep_state, data, actions}
  end
  # Call Events
  def handle_event({:call, from}, :read, :subscribed, _data = %Data{ record: record }) do
    actions = [{:reply, from, record}]
    {:keep_state_and_data, actions}
  end
  def handle_event({:call, from}, :read, _state, data = %Data{ calls: calls }) do
    calls = :queue.in(from, calls)
    data = %{ data | calls: calls }
    {:keep_state, data}
  end
  # Cast Events
  def handle_event(:cast, {:subscribe, _pid}, _state, _data = %Data{ record: record }) do
    :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, record, [
      observe_cortex: <<>>
    ])
    :keep_state_and_data
  end
  def handle_event(:cast, :stop, _state, _data) do
    {:stop, :normal}
  end
  # Info Events
  def handle_event(:info, {@target, {:cortex, cortex}}, state, data = %Data{ record: record }) do
    record = Map.merge(record, cortex)
    data = %{ data | record: record }
    :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, record, [
      observe_cortex: <<>>
    ])
    if state == :unsubscribed do
      {:next_state, :subscribed, data}
    else
      {:keep_state, data}
    end
  end

  # def terminate(_reason, _state, _data) do
  #   require Logger
  #   Logger.info("STOPPING CORTEX SUBSCRIBE")
  #   :ok
  # end

  @doc false
  defp flush(calls, record, actions) do
    case :queue.out(calls) do
      {{:value, from}, new_calls} ->
        actions = [{:reply, from, record} | actions]
        flush(new_calls, record, actions)
      {:empty, ^calls} ->
        actions
    end
  end

end