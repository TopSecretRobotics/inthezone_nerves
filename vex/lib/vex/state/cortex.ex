defmodule Vex.State.Cortex do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  # @maybe_stop 1000
  # @resubscribe 1000

  @events Vex.State.Events
  @server Vex.Local.Server
  @server_events Vex.Local.Server.Events
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
      backup_battery: nil,
      connected: nil,
      main_battery: nil,
      ticks: nil
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    data = %Data{}
    :ok = @server_events.subscribe_status()
    :ok = @server_events.subscribe_frames()
    state =
      if @server.connected?() do
        :connected
      else
        :disconnected
      end
    {:ok, state, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, _old_state, :connected, data) do
    :ok = @events.cortex(%{
      backup_battery: 0,
      connected: true,
      main_battery: 0,
      ticks: 0
    })
    data = %{
      data |
      backup_battery: 0,
      connected: true,
      main_battery: 0,
      ticks: 0
    }
    {:keep_state, data}
  end
  def handle_event(:enter, _old_state, :disconnected, data) do
    :ok = @events.cortex(%{
      backup_battery: 0,
      connected: false,
      main_battery: 0,
      ticks: 0
    })
    data = %{
      data |
      backup_battery: 0,
      connected: false,
      main_battery: 0,
      ticks: 0
    }
    {:keep_state, data}
  end
  # Cast Events
  def handle_event(:cast, {:subscribe, pid}, _state, _data = %Data{
    backup_battery: backup_battery,
    connected: connected,
    main_battery: main_battery,
    ticks: ticks
  }) do
    cortex = %{
      backup_battery: backup_battery,
      connected: connected,
      main_battery: main_battery,
      ticks: ticks
    }
    _ = :erlang.send(pid, {@target, {:cortex, cortex}})
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
  def handle_event(:info, {@server, :frame, {:in, info_frame = %Vex.Frame.INFO{}}}, :connected, data) do
    case Vex.Message.decode(info_frame) do
      {:ok, %Vex.Message.Info.Robot.Spi{ value: {ticks, main_battery, backup_battery} }} ->
        :ok = @events.cortex(%{
          backup_battery: backup_battery,
          connected: true,
          main_battery: main_battery,
          ticks: ticks
        })
        data = %{
          data |
          backup_battery: backup_battery,
          main_battery: main_battery,
          ticks: ticks
        }
        {:keep_state, data}
      _ ->
        # require Logger
        # Logger.info("[0] ignoring: #{inspect info_frame}")
        :keep_state_and_data
    end
  end
  def handle_event(:info, {@server, :frame, {event, _frame}}, _state, _data) when event in [:in, :out] do
    # require Logger
    # Logger.info("[1] ignoring: #{inspect _frame}")
    :keep_state_and_data
  end

  # @impl GenStateMachine
  # # def terminate(_reason, :connected, _data = %Data{ subscription: subscription }) do
  # #   require Logger
  # #   Logger.info("UNSUBSCRIBING SUBSCRIBER")
  # #   _ = Vex.RPC.unsubscribe(subscription)
  # #   :ok
  # # end
  # def terminate(_reason, _state, _data) do
  #   require Logger
  #   Logger.info("STOPPING CORTEX")
  #   :ok
  # end

end