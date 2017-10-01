defmodule Vex.State.Motors do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  # @maybe_stop 1000
  # @resubscribe 1000

  @events Vex.State.Events
  @server Vex.Local.Server
  @target Vex.State

  def start_link() do
    GenStateMachine.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def connected?() do
    @server.connected?()
  end

  def subscribe(pid) do
    GenStateMachine.cast(__MODULE__, {:subscribe, pid})
  end

  def stop() do
    GenStateMachine.cast(__MODULE__, :stop)
  end

  defmodule Data do
    defstruct [
      motor_state: nil
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    data = %Data{}
    {:ok, :init, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, :init, :init, _data) do
    actions = [{:state_timeout, 0, :start}]
    {:keep_state_and_data, actions}
  end
  def handle_event(:enter, _old_state, :connected, _data) do
    actions = [{:state_timeout, 0, :read}]
    {:keep_state_and_data, actions}
  end
  def handle_event(:enter, _old_state, :subscribed, _data) do
    :keep_state_and_data
  end
  def handle_event(:enter, _old_state, :disconnected, _data) do
    :keep_state_and_data
  end
  # State Timeout Events
  def handle_event(:state_timeout, :start, :init, data) do
    :ok = @events.subscribe_status()
    :ok = @events.subscribe_frames()
    state =
      if @server.connected?() do
        :connected
      else
        :disconnected
      end
    {:next_state, state, data}
  end
  def handle_event(:state_timeout, :read, :connected, data) do
    result =
      try do
        Vex.RPC.read(:motor, :all)
      catch _, _ ->
        :error
      end
    # require Logger
    # Logger.info("result: #{inspect result}")
    case result do
      {:ok, %Vex.Message.Data.Motor.All{ ticks: ticks, value: value }} ->
        :ok = @events.motor_state(ticks, value)
        motor_state = Vex.MotorState.new()
        motor_state = Vex.MotorState.add(motor_state, ticks, value)
        data = %{ data | motor_state: motor_state }
        {:next_state, :subscribed, data}
      :error ->
        actions = [{:state_timeout, 1000, :read}]
        {:keep_state_and_data, actions}
    end
  end
  # Cast Events
  def handle_event(:cast, {:subscribe, pid}, :subscribed, _data = %Data{ motor_state: %{ current: {ticks, value} } }) do
    _ = :erlang.send(pid, {@target, {:motor_state, ticks, value}})
    :keep_state_and_data
  end
  def handle_event(:cast, {:subscribe, _}, _state, _data) do
    :keep_state_and_data
  end
  def handle_event(:cast, :stop, _state, _data) do
    {:stop, :normal}
  end
  # Info Events
  def handle_event(:info, {@target, {:status, :connected}}, :disconnected, data) do
    {:next_state, :connected, data}
  end
  def handle_event(:info, {@target, {:status, :disconnected}}, state, data) when state != :disconnected do
    {:next_state, :disconnected, data}
  end
  def handle_event(:info, {@target, {:status, event}}, _state, _data) when event in [:connected, :disconnected] do
    :keep_state_and_data
  end
  def handle_event(:info, {@target, {:frame_data, frame}}, :subscribed, data = %Data{ motor_state: motor_state }) do
    case frame do
      %Vex.Message.Data.Motor.All{ ticks: ticks, value: value } ->
        # require Logger
        # Logger.info("motors: #{inspect value}")
        value = Vex.MotorState.fill(motor_state, value)
        old_value = Vex.MotorState.value(motor_state)
        motor_state = Vex.MotorState.add(motor_state, ticks, value)
        new_value = Vex.MotorState.value(motor_state)
        data = %{ data | motor_state: motor_state }
        if old_value != new_value do
          [{ticks, change} | _] = motor_state.entries
          :ok = @events.motor_state(ticks, change)
        end
        {:keep_state, data}
      _ ->
        :keep_state_and_data
    end
    # require Logger
    # Logger.info("frame: #{inspect frame}")
  end
  def handle_event(:info, {@target, {event, _}}, _state, _data) when event in [:frame_data, :frame_error] do
    :keep_state_and_data
  end
  def handle_event(:info, {@target, :frame_end}, _state, _data) do
    :keep_state_and_data
  end
  # def handle_event(:info, {subscription, event}, :subscribed, data = %Data{ subscription: subscription }) when is_reference(subscription) do
  #   case event do
  #     {:data, data_frame} ->
  #       case Vex.Message.decode(data_frame) do
  #         {:ok, data_message} ->
  #           :ok = @events.frame_data(data_message)
  #           :keep_state_and_data
  #         :error ->
  #           :keep_state_and_data
  #       end
  #     {:error, data_frame} ->
  #       case Vex.Message.decode(data_frame) do
  #         {:ok, data_message} ->
  #           :ok = @events.frame_error(data_message)
  #           {:next_state, :connected, data}
  #         :error ->
  #           {:next_state, :connected, data}
  #       end
  #     :end ->
  #       :ok = @events.frame_end()
  #       data = %{ data | subscription: nil }
  #       {:next_state, :connected, data}
  #   end
  # end
  # def handle_event(:info, {subscription, event}, _state, _data) when is_reference(subscription) and event in [:end, :error] do
  #   :keep_state_and_data
  # end
  # def handle_event(:info, {:DOWN, _monitor, :process, pid, _reason}, _state, data = %Data{ counters: counters, monitors: monitors }) do
  #   counters = Map.delete(counters, pid)
  #   monitors = Map.delete(monitors, pid)
  #   data = %{ data | counters: counters, monitors: monitors }
  #   actions = [{{:timeout, :maybe_stop}, @maybe_stop, :soft}]
  #   {:keep_state, data, actions}
  # end

  @impl GenStateMachine
  # def terminate(_reason, :connected, _data = %Data{ subscription: subscription }) do
  #   require Logger
  #   Logger.info("UNSUBSCRIBING SUBSCRIBER")
  #   _ = Vex.RPC.unsubscribe(subscription)
  #   :ok
  # end
  def terminate(_reason, _state, _data) do
    require Logger
    Logger.info("STOPPING MOTORS")
    :ok
  end

end