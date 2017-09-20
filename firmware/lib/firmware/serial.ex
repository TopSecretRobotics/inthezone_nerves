defmodule Firmware.Serial do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]
  use Bitwise
  # require Logger

  @device "ttyS0"
  @uart_open_timeout 1000
  @sfp_connect_timeout 2000
  @sfp_heartbeat_timeout 5000
  @sfp_heartattack_timeout 2000

  def start_link() do
    GenStateMachine.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def connected?() do
    GenStateMachine.call(__MODULE__, :is_connected, :infinity)
  end

  def write(iodata) do
    GenStateMachine.cast(__MODULE__, {:write, iodata})
  end

  defmodule Data do
    defstruct [
      heartbeat: 0,
      sfp: nil,
      uart: nil
    ]
  end

  alias __MODULE__.Data, as: Data

  def init([]) do
    {:ok, uart} = Nerves.UART.start_link()
    sfp = :serial_framing_protocol_nif.open()
    data = %Data{
      sfp: sfp,
      uart: uart
    }
    {:ok, :uart_closed, data}
  end

  # Enter Events
  def handle_event(:enter, old_state, :uart_closed, data) do
    case old_state do
      :uart_closed ->
        :ok
      :sfp_disconnected ->
        :ok
      _ ->
        Vex.Server.disconnected()
    end
    {:keep_state, %{ data | heartbeat: 0 }, [{:state_timeout, @uart_open_timeout, :uart_open}]}
  end
  def handle_event(:enter, old_state, :sfp_disconnected, data) do
    case old_state do
      :uart_closed ->
        :ok
      :sfp_disconnected ->
        :ok
      _ ->
        Vex.Server.disconnected()
    end
    {:keep_state, %{ data | heartbeat: 0 }, [{:state_timeout, @sfp_connect_timeout, :sfp_connect}]}
  end
  def handle_event(:enter, old_state, :sfp_connected, _data) do
    case old_state do
      :sfp_connected ->
        :ok
      :sfp_connected_heartbeat ->
        :ok
      _ ->
        Vex.Server.connected()
    end
    {:keep_state_and_data, [{:state_timeout, @sfp_heartbeat_timeout, :sfp_heartbeat}]}
  end
  def handle_event(:enter, _old_state, :sfp_connected_heartbeat, _data) do
    {:keep_state_and_data, [{:state_timeout, @sfp_heartattack_timeout, :sfp_heartattack}]}
  end
  # State Timeout Events
  def handle_event(:state_timeout, :uart_open, :uart_closed, data = %Data{ sfp: sfp, uart: uart }) do
    options = [
      active: true,
      # parity: :odd,
      stop_bits: 1,
      speed: 115200
    ]
    case Nerves.UART.open(uart, @device, options) do
      :ok ->
        :ok = :serial_framing_protocol_nif.init(sfp)
        :ok = :serial_framing_protocol_nif.connect(sfp)
        {:next_state, :sfp_disconnected, data}
      _ ->
        {:keep_state_and_data, [{:state_timeout, @uart_open_timeout, :uart_open}]}
    end
  end
  def handle_event(:state_timeout, :sfp_connect, :sfp_disconnected, _data = %Data{ sfp: sfp }) do
    :ok = :serial_framing_protocol_nif.init(sfp)
    :ok = :serial_framing_protocol_nif.connect(sfp)
    {:keep_state_and_data, [{:state_timeout, @sfp_connect_timeout, :sfp_connect}]}
  end
  def handle_event(:state_timeout, :sfp_heartbeat, :sfp_connected, data = %Data{ heartbeat: heartbeat, sfp: sfp }) do
    ping = Vex.Message.ping_frame(heartbeat)
    {:ok, frame} = Vex.Message.encode(ping)
    :ok = :serial_framing_protocol_nif.write(sfp, frame)
    {:next_state, :sfp_connected_heartbeat, data}
  end
  def handle_event(:state_timeout, :sfp_heartattack, :sfp_connected_heartbeat, data = %Data{ sfp: sfp, uart: uart }) do
    _ = Nerves.UART.close(uart)
    :ok = :serial_framing_protocol_nif.init(sfp)
    {:next_state, :uart_closed, data}
  end
  # Call Events
  def handle_event({:call, from}, :is_connected, _state, _data = %Data{ sfp: sfp }) do
    reply = :serial_framing_protocol_nif.is_connected(sfp)
    {:keep_state_and_data, [{:reply, from, reply}]}
  end
  # Cast Events
  def handle_event(:cast, {:write, iodata}, state, _data = %Data{ sfp: sfp }) when state in [:sfp_connected, :sfp_connected_heartbeat] do
    :ok = :serial_framing_protocol_nif.write(sfp, iodata)
    :keep_state_and_data
  end
  def handle_event(:cast, {:write, _}, _state, _data) do
    :keep_state_and_data
  end
  # Info Events
  def handle_event(:info, {:nerves_uart, _, _}, :uart_closed, _data) do
    :keep_state_and_data
  end
  def handle_event(:info, {:nerves_uart, _, {:error, _}}, state, data = %Data{ sfp: sfp, uart: uart }) when state != :uart_closed do
    _ = Nerves.UART.close(uart)
    :ok = :serial_framing_protocol_nif.init(sfp)
    {:next_state, :uart_closed, data}
  end
  def handle_event(:info, {:nerves_uart, @device, iodata}, state, _data = %Data{ sfp: sfp }) when is_binary(iodata) or is_list(iodata) when state != :uart_closed do
    # if iodata != << 0 >> do
    #   Logger.info("UART [r] -> #{inspect iodata}")
    # end
    :ok = :serial_framing_protocol_nif.read(sfp, iodata)
    :keep_state_and_data
  end
  def handle_event(:info, {:sfp, :write, packet}, state, data = %Data{ sfp: sfp, uart: uart }) when state in [:sfp_disconnected, :sfp_connected, :sfp_connected_heartbeat] do
    # Logger.info("UART [w] -> #{inspect packet}")
    case Nerves.UART.write(uart, packet) do
      :ok ->
        check_sfp_connection(state, data)
      _ ->
        _ = Nerves.UART.close(uart)
        :ok = :serial_framing_protocol_nif.init(sfp)
        {:next_state, :uart_closed, data}
    end
  end
  def handle_event(:info, {:sfp, :read, packet}, state, data = %Data{ heartbeat: heartbeat, sfp: sfp, uart: uart }) when state in [:sfp_disconnected, :sfp_connected, :sfp_connected_heartbeat] do
    # Logger.info("SFP [r] -> #{inspect packet}")
    case Vex.Message.decode(packet) do
      {:ok, %Vex.Message.PONG{ seq_id: ^heartbeat }} ->
        heartbeat = (heartbeat + 1) &&& 0xff
        data = %{ data | heartbeat: heartbeat }
        check_sfp_connection({state, :sfp_connected}, data)
      {:ok, %Vex.Message.PONG{}} ->
        _ = Nerves.UART.close(uart)
        :ok = :serial_framing_protocol_nif.init(sfp)
        {:next_state, :uart_closed, data}
      {:ok, message} ->
        :ok = Vex.Server.handle_message(message)
        check_sfp_connection(state, data)
      :error ->
        check_sfp_connection(state, data)
    end
  end

  @doc false
  defp check_sfp_connection(:sfp_disconnected, data = %Data{ sfp: sfp }) do
    if :serial_framing_protocol_nif.is_connected(sfp) do
      {:next_state, :sfp_connected, data}
    else
      :keep_state_and_data
    end
  end
  defp check_sfp_connection(:sfp_connected, data = %Data{ sfp: sfp }) do
    if :serial_framing_protocol_nif.is_connected(sfp) do
      :keep_state_and_data
    else
      {:next_state, :sfp_disconnected, data}
    end
  end
  defp check_sfp_connection(:sfp_connected_heartbeat, data = %Data{ sfp: sfp }) do
    if :serial_framing_protocol_nif.is_connected(sfp) do
      :keep_state_and_data
    else
      {:next_state, :sfp_disconnected, data}
    end
  end
  defp check_sfp_connection({:sfp_connected_heartbeat, :sfp_connected}, data = %Data{ sfp: sfp }) do
    if :serial_framing_protocol_nif.is_connected(sfp) do
      {:next_state, :sfp_connected, data}
    else
      {:next_state, :sfp_disconnected, data}
    end
  end
end