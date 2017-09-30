defmodule Vex.Robot.UdpSocket do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @priority 10
  @reopen 1000
  @wait 2

  @events Vex.Robot.Server.Socket.Events
  @udp :gen_udp

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

  defmodule Data do
    defstruct [
      port: nil,
      udp: nil,
      udp_buffer: <<>>,
      udp_address: nil,
      udp_port: nil,
      udp_wait: false,
      vex_buffer: <<>>,
      vex_wait: false
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    true = Vex.Robot.IO.register_input(@priority, :erlang.self())
    port = Application.get_env(:vex, :nerves_socket_udp_local_port, 31389)
    udp_address = Application.get_env(:vex, :nerves_socket_udp_remote_address, {192, 168, 86, 30})
    udp_port = Application.get_env(:vex, :nerves_socket_udp_remote_port, 31388)
    data = %Data{
      port: port,
      udp_address: udp_address,
      udp_port: udp_port
    }
    {:ok, :closed, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, _old_state, :open, _data) do
    :keep_state_and_data
  end
  def handle_event(:enter, _old_state, :closed, _data) do
    {:keep_state_and_data, [{:state_timeout, 0, :open}]}
  end
  # State Timeout Events
  def handle_event(:state_timeout, :open, :closed, data = %{ port: port }) do
    udp_opts = [
      :binary,
      :inet,
      {:active, :once},
      {:ip, {0, 0, 0, 0}},
      {:port, port},
      {:reuseaddr, true}
    ]
    case @udp.open(0, udp_opts) do
      {:ok, udp} ->
        data = %{ data | udp: udp }
        {:next_state, :open, data}
      _ ->
        {:keep_state_and_data, [{:state_timeout, @reopen, :open}]}
    end
  end
  # Generic Timeout Events
  def handle_event({:timeout, :udp}, :wait, :open, data = %{ udp: udp, udp_buffer: iodata, udp_wait: true }) do
    data = %{ data | udp_buffer: <<>>, udp_wait: false }
    # require Logger
    # Logger.info("out #{inspect iodata}")
    :ok = @events.frame_out(iodata)
    :ok = Vex.Robot.IO.output(iodata)
    :ok = :inet.setopts(udp, [{:active, :once}])
    {:keep_state, data}
  end
  def handle_event({:timeout, :vex}, :wait, :open, data = %{ vex_buffer: iodata, vex_wait: true, udp: udp, udp_address: address, udp_port: port }) when address != nil and port != nil do
    data = %{ data | vex_buffer: <<>>, vex_wait: false }
    # require Logger
    # Logger.info("in  #{inspect iodata}")
    :ok = @events.frame_in(iodata)
    case @udp.send(udp, address, port, iodata) do
      :ok ->
        {:keep_state, data}
      _ ->
        data = cleanup(data)
        {:next_state, :closed, data}
    end
  end
  def handle_event({:timeout, name}, :wait, _state, _data) when name in [:vex, :udp] do
    :keep_state_and_data
  end
  # Call Events
  def handle_event({:call, from}, :is_connected, state, _data) do
    reply =
      if state == :open do
        true
      else
        false
      end
    {:keep_state_and_data, [{:reply, from, reply}]}
  end
  # Cast Events
  def handle_event(:cast, :disconnect, :closed, _data) do
    :keep_state_and_data
  end
  def handle_event(:cast, :disconnect, :open, data) do
    data = cleanup(data)
    {:next_state, :closed, data}
  end
  # Info Events
  def handle_event(:info, {:vex_robot_input, _iodata}, :closed, _data) do
    :keep_state_and_data
  end
  def handle_event(:info, {:vex_robot_input, iodata}, :open, data = %Data{ vex_buffer: buffer, vex_wait: wait }) do
    buffer = << buffer :: binary(), iodata :: binary() >>
    data = %{ data | vex_buffer: buffer }
    if wait do
      {:keep_state, data}
    else
      data = %{ data | vex_wait: true }
      actions = [{{:timeout, :vex}, @wait, :wait}]
      {:keep_state, data, actions}
    end
  end
  def handle_event(:info, {:udp, _udp, _address, _port, _packet}, :closed, _data) do
    :keep_state_and_data
  end
  def handle_event(:info, {:udp, udp, address, port, iodata}, :open, data = %Data{ udp: udp, udp_buffer: buffer, udp_wait: false, udp_address: address, udp_port: port }) do
    buffer = << buffer :: binary(), iodata :: binary() >>
    data = %{ data | udp_buffer: buffer, udp_wait: true }
    actions = [{{:timeout, :udp}, @wait, :wait}]
    {:keep_state, data, actions}
  end

  @doc false
  defp cleanup(data = %{ udp: udp }) do
    if udp != nil do
      :ok = @udp.close(udp)
    end
    %{ data | vex_buffer: <<>>, vex_wait: false, udp: nil, udp_buffer: <<>>, udp_wait: false }
  end

end
