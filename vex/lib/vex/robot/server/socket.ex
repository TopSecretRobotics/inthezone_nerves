defmodule Vex.Robot.Server.Socket do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @priority 0

  @events Vex.Robot.Server.Socket.Events
  @protocol Vex.SerialFramingProtocol
  @server Vex.Robot.Server

  def start_link() do
    GenStateMachine.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def connected?() do
    case :erlang.whereis(__MODULE__) do
      :undefined ->
        false
      _ ->
        GenStateMachine.call(__MODULE__, :is_connected, :infinity)
    end
  end

  def disconnect() do
    GenStateMachine.cast(__MODULE__, :disconnect)
  end

  def write(iodata) do
    GenStateMachine.cast(__MODULE__, {:write, iodata})
  end

  defmodule Data do
    defstruct [
      sfp: nil
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    true = Vex.Robot.IO.register_input(@priority, :erlang.self())
    {state, sfp} = @protocol.init([])
    data = %Data{
      sfp: sfp
    }
    {:ok, state, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, _old_state, :connected, _data) do
    :ok = @events.connected()
    :keep_state_and_data
  end
  def handle_event(:enter, _old_state, :disconnected, _data) do
    :ok = @events.disconnected()
    :keep_state_and_data
  end
  # Call Events
  def handle_event({:call, from}, :is_connected, state, _data) do
    reply =
      if state == :connected do
        true
      else
        false
      end
    {:keep_state_and_data, [{:reply, from, reply}]}
  end
  # Cast Events
  def handle_event(:cast, :disconnect, :disconnected, _data) do
    :keep_state_and_data
  end
  def handle_event(:cast, :disconnect, :connected, data = %Data{ sfp: sfp }) do
    {:disconnected, ^sfp} = @protocol.reset(sfp, :connected)
    {:next_state, :disconnected, data}
  end
  def handle_event(:cast, {:write, iodata}, state, data = %{ sfp: sfp }) do
    case @protocol.write(sfp, state, iodata) do
      {^state, ^sfp} ->
        :keep_state_and_data
      {^state, sfp} ->
        data = %{ data | sfp: sfp }
        {:keep_state, data}
      {new_state, sfp} ->
        data = %{ data | sfp: sfp }
        {:next_state, new_state, data}
    end
  end
  # Info Events
  def handle_event(:info, {:sfp, :read, iodata}, _state, _data) do
    case Vex.Frame.decode(iodata) do
      {:ok, frame} ->
        :ok = @server.vex_rpc_recv(frame)
        :keep_state_and_data
      :error ->
        :keep_state_and_data
    end
  end
  def handle_event(:info, {:sfp, :write, iodata}, _state, _data) do
    :ok = @events.frame_out(iodata)
    :ok = Vex.Robot.IO.output(iodata)
    :keep_state_and_data
  end
  def handle_event(:info, {:vex_robot_input, iodata}, state, data = %Data{ sfp: sfp }) do
    :ok = @events.frame_in(iodata)
    case @protocol.read(sfp, state, iodata) do
      {^state, ^sfp} ->
        :keep_state_and_data
      {^state, sfp} ->
        data = %{ data | sfp: sfp }
        {:keep_state, data}
      {new_state, sfp} ->
        data = %{ data | sfp: sfp }
        {:next_state, new_state, data}
    end
  end

end