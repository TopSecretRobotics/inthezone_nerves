defmodule SerialUdp.Socket do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @reopen 1000
  @wait 2
  @udp_port 31388

  @uart Nerves.UART
  @udp :gen_udp

  def start_link() do
    GenStateMachine.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def connected?() do
    GenStateMachine.call(__MODULE__, :is_connected, :infinity)
  end

  def disconnect() do
    GenStateMachine.cast(__MODULE__, :disconnect)
  end

  defmodule Data do
    defstruct [
      device: nil,
      options: nil,
      uart: nil,
      uart_buffer: <<>>,
      uart_wait: false,
      udp: nil,
      udp_buffer: <<>>,
      udp_address: nil,
      udp_port: nil,
      udp_wait: false
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    device = Application.get_env(:serial_udp, :nerves_socket_device, "ttyS0")
    options = Application.get_env(:serial_udp, :nerves_socket_device_options, [
      data_bits: 8,
      parity: :none,
      stop_bits: 1,
      speed: 115200
    ])
    options = Keyword.put(options, :active, true)
    {:ok, uart} = @uart.start_link()
    data = %Data{
      device: device,
      options: options,
      uart: uart
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
  def handle_event(:state_timeout, :open, :closed, data = %{ device: device, options: options, uart: uart }) do
    with :ok <- @uart.open(uart, device, options),
         :ok <- @uart.flush(uart, :both) do
      udp_opts = [
        :binary,
        :inet,
        {:active, :once},
        {:ip, {0, 0, 0, 0}},
        {:port, @udp_port},
        {:reuseaddr, true}
      ]
      case @udp.open(0, udp_opts) do
        {:ok, udp} ->
          data = %{ data | udp: udp }
          {:next_state, :open, data}
        _ ->
          _ = @uart.close(uart)
          {:keep_state_and_data, [{:state_timeout, @reopen, :open}]}
      end
    else _ ->
      {:keep_state_and_data, [{:state_timeout, @reopen, :open}]}
    end
  end
  # Generic Timeout Events
  def handle_event({:timeout, :udp}, :wait, :open, data = %{ uart: uart, udp: udp, udp_buffer: iodata, udp_wait: true }) do
    data = %{ data | udp_buffer: <<>>, udp_wait: false }
    with :ok <- @uart.write(uart, iodata),
         :ok <- @uart.drain(uart) do
      # require Logger
      # Logger.info("in  #{inspect iodata}")
      :ok = :inet.setopts(udp, [{:active, :once}])
      {:keep_state, data}
    else _ ->
      data = cleanup(data)
      {:next_state, :closed, data}
    end
  end
  def handle_event({:timeout, :uart}, :wait, :open, data = %{ uart: uart, uart_buffer: iodata, uart_wait: true, udp: udp, udp_address: address, udp_port: port }) when address != nil and port != nil do
    data = %{ data | uart_buffer: <<>>, uart_wait: false }
    # require Logger
    # Logger.info("out #{inspect iodata}")
    case @udp.send(udp, address, port, iodata) do
      :ok ->
        :ok = @uart.configure(uart, active: true)
        {:keep_state, data}
      _ ->
        data = cleanup(data)
        {:next_state, :closed, data}
    end
  end
  def handle_event({:timeout, name}, :wait, _state, _data) when name in [:uart, :udp] do
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
  def handle_event(:info, {:udp, _udp, _address, _port, _packet}, :closed, _data) do
    :keep_state_and_data
  end
  def handle_event(:info, {:udp, udp, address, port, iodata}, :open, data = %Data{ udp: udp, udp_buffer: buffer, udp_wait: false }) do
    buffer = << buffer :: binary(), iodata :: binary() >>
    data = %{ data | udp_address: address, udp_port: port, udp_buffer: buffer, udp_wait: true }
    actions = [{{:timeout, :udp}, @wait, :wait}]
    {:keep_state, data, actions}
  end
  def handle_event(:info, {:nerves_uart, _, _}, :closed, _data) do
    :keep_state_and_data
  end
  def handle_event(:info, {:nerves_uart, _, {:error, _reason}}, :open, data) do
    data = cleanup(data)
    {:next_state, :closed, data}
  end
  def handle_event(:info, {:nerves_uart, device, iodata}, :open, data = %Data{ device: device, uart: uart, uart_buffer: buffer, uart_wait: wait }) do
    buffer = << buffer :: binary(), iodata :: binary() >>
    data = %{ data | uart_buffer: buffer }
    if wait do
      {:keep_state, data}
    else
      data = %{ data | uart_wait: true }
      :ok = @uart.configure(uart, active: false)
      actions = [{{:timeout, :uart}, @wait, :wait}]
      {:keep_state, data, actions}
    end
  end

  @doc false
  defp cleanup(data = %{ uart: uart, udp: udp }) do
    _ = @uart.close(uart)
    if udp != nil do
      :ok = @udp.close(udp)
    end
    %{ data | uart_buffer: <<>>, uart_wait: false, udp: nil, udp_buffer: <<>>, udp_address: nil, udp_port: nil, udp_wait: false }
  end

end
