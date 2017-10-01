defmodule Vex.State.Subscriber do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @resubscribe 1000

  @events Vex.State.Events
  @server Vex.Local.Server
  @server_events Vex.Local.Server.Events

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
      subscription: nil
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    data = %Data{}
    :ok = @server_events.subscribe_status()
    state =
      if @server.connected?() do
        :ok = @events.status_connected()
        :connected
      else
        :ok = @events.status_disconnected()
        :disconnected
      end
    {:ok, state, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, old_state, :connected, _data) do
    if old_state == :disconnected do
      :ok = @events.status_connected()
    end
    actions = [{:state_timeout, 0, :subscribe}]
    {:keep_state_and_data, actions}
  end
  def handle_event(:enter, _old_state, :subscribed, _data) do
    :keep_state_and_data
  end
  def handle_event(:enter, old_state, :disconnected, data) do
    if old_state != :disconnected do
      :ok = @events.status_disconnected()
    end
    data = %{ data | subscription: nil }
    {:keep_state, data}
  end
  # State Timeout Events
  def handle_event(:state_timeout, :subscribe, :connected, data = %Data{ subscription: nil }) do
    case Vex.RPC.subscribe(:motor, :all) do
      {:ok, subscription} ->
        data = %{ data | subscription: subscription }
        {:next_state, :subscribed, data}
      _ ->
        actions = [{:state_timeout, @resubscribe, :subscribe}]
        {:keep_state_and_data, actions}
    end
  end
  # Cast Events
  # def handle_event(:cast, {:subscribe, pid}, :subscribed, _data = %Data{ motor_state: %{ current: {ticks, value} } }) do
  #   _ = :erlang.send(pid, {@target, {:motor_state, ticks, value}})
  #   :keep_state_and_data
  # end
  def handle_event(:cast, {:subscribe, _}, _state, _data) do
    :keep_state_and_data
  end
  def handle_event(:cast, :stop, _state, _data) do
    {:stop, :normal}
  end
  # Info Events
  def handle_event(:info, {@server, :status, :connected}, :disconnected, data) do
    {:next_state, :connected, data}
  end
  def handle_event(:info, {@server, :status, :disconnected}, state, data) when state != :disconnected do
    {:next_state, :disconnected, data}
  end
  def handle_event(:info, {@server, :status, event}, _state, _data) when event in [:connected, :disconnected] do
    :keep_state_and_data
  end
  def handle_event(:info, {subscription, event}, :subscribed, data = %Data{ subscription: subscription }) when is_reference(subscription) do
    # require Logger
    # Logger.info("FREAKING WHY: #{inspect event}")
    case event do
      {:data, data_frame} ->
        case Vex.Message.decode(data_frame) do
          {:ok, data_message} ->
            :ok = @events.frame_data(data_message)
            :keep_state_and_data
          :error ->
            :keep_state_and_data
        end
      {:error, data_frame} ->
        case Vex.Message.decode(data_frame) do
          {:ok, data_message} ->
            :ok = @events.frame_error(data_message)
            data = %{ data | subscription: nil }
            {:next_state, :connected, data}
          :error ->
            {:next_state, :connected, data}
        end
      :end ->
        :ok = @events.frame_end()
        data = %{ data | subscription: nil }
        {:next_state, :connected, data}
    end
  end
  def handle_event(:info, {subscription, event}, _state, _data) when is_reference(subscription) and event in [:end, :error] do
    :keep_state_and_data
  end

  @impl GenStateMachine
  def terminate(_reason, :connected, _data = %Data{ subscription: subscription }) do
    require Logger
    Logger.info("UNSUBSCRIBING SUBSCRIBER")
    _ = Vex.RPC.unsubscribe(subscription)
    :ok
  end
  def terminate(_reason, _state, _data) do
    require Logger
    Logger.info("STOPPING SUBSCRIBER")
    :ok
  end

end