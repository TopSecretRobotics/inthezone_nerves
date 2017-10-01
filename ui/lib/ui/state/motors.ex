defmodule Ui.State.Motors do
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
      motors: []
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    motors =
      for index <- 0..9, into: [] do
        %Ui.Data.Motor{
          id: index,
          index: index,
          ticks: 0,
          value: 0
        }
      end
    data = %Data{
      motors: motors
    }
    {:ok, :unsubscribed, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, _old_state, :unsubscribed, _data) do
    :ok = @events.subscribe_motors()
    actions = [{:state_timeout, 500, :flush}]
    {:keep_state_and_data, actions}
  end
  def handle_event(:enter, _old_state, :subscribed, data = %Data{ calls: calls, motors: motors }) do
    data = %{ data | calls: :queue.new() }
    actions = flush(calls, motors, [])
    {:keep_state, data, actions}
  end
  # State Timeout Events
  def handle_event(:state_timeout, :flush, :unsubscribed, data = %Data{ calls: calls, motors: motors }) do
    data = %{ data | calls: :queue.new() }
    actions = [{:state_timeout, 500, :flush}]
    actions = flush(calls, motors, actions)
    {:keep_state, data, actions}
  end
  # Call Events
  def handle_event({:call, from}, :read, :subscribed, _data = %Data{ motors: motors }) do
    actions = [{:reply, from, motors}]
    {:keep_state_and_data, actions}
  end
  def handle_event({:call, from}, :read, _state, data = %Data{ calls: calls }) do
    calls = :queue.in(from, calls)
    data = %{ data | calls: calls }
    {:keep_state, data}
  end
  # Cast Events
  def handle_event(:cast, {:subscribe, _pid}, _state, _data = %Data{ motors: motors }) do
    :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, motors, [
      observe_motors: <<>>
    ])
    :keep_state_and_data
  end
  def handle_event(:cast, :stop, _state, _data) do
    {:stop, :normal}
  end
  # Info Events
  def handle_event(:info, {@target, {:motor_state, ticks, values}}, state, data = %Data{ motors: motors }) do
    changes =
      for {index, value} <- values, into: [] do
        %Ui.Data.Motor{
          id: index,
          index: index,
          ticks: ticks,
          value: value
        }
      end
    motors =
      if motors == [] do
        changes
      else
        update(motors, changes, [])
      end
    data = %{ data | motors: motors }
    # require Logger
    # Logger.info("changes: #{inspect changes}")
    :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, changes, [
      observe_motors: <<>>
    ])
    if state == :unsubscribed do
      {:next_state, :subscribed, data}
    else
      {:keep_state, data}
    end
  end

  # @impl GenStateMachine
  # def terminate(_reason, _state, _data) do
  #   require Logger
  #   Logger.info("STOPPING MOTORS SUBSCRIBE")
  #   :ok
  # end

  @doc false
  defp flush(calls, motors, actions) do
    case :queue.out(calls) do
      {{:value, from}, new_calls} ->
        actions = [{:reply, from, motors} | actions]
        flush(new_calls, motors, actions)
      {:empty, ^calls} ->
        actions
    end
  end

  @doc false
  defp update([%{ index: index } | old], [motor = %{ index: index } | new], acc) do
    update(old, new, [motor | acc])
  end
  defp update([motor | old], new, acc) do
    update(old, new, [motor | acc])
  end
  defp update([], [], acc) do
    :lists.reverse(acc)
  end

end