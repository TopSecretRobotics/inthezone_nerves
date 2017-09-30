if Code.ensure_loaded?(Nerves.UART) do

  defmodule Vex.Robot.NervesSocket do
    use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

    @priority 100
    @reopen 1000

    @events Vex.Robot.Server.Socket.Events
    @uart Nerves.UART

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
        uart: nil
      ]
    end

    alias __MODULE__.Data, as: Data

    @impl GenStateMachine
    def init([]) do
      true = Vex.Robot.IO.register_input(@priority, :erlang.self())
      device = Application.get_env(:vex, :nerves_socket_device, "ttyS0")
      options = Application.get_env(:vex, :nerves_socket_device_options, [
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
      # :ok = @server.vex_socket_connected()
      :keep_state_and_data
    end
    def handle_event(:enter, _old_state, :closed, _data) do
      # :ok = @server.vex_socket_disconnected()
      {:keep_state_and_data, [{:state_timeout, @reopen, :open}]}
    end
    # State Timeout Events
    def handle_event(:state_timeout, :open, :closed, data = %{ device: device, options: options, uart: uart }) do
      case @uart.open(uart, device, options) do
        :ok ->
          {:next_state, :open, data}
        _ ->
          {:keep_state_and_data, [{:state_timeout, @reopen, :open}]}
      end
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
    def handle_event(:cast, :disconnect, :open, data = %Data{ uart: uart }) do
      _ = Nerves.UART.close(uart)
      {:next_state, :closed, data}
    end
    # Info Events
    def handle_event(:info, {:vex_robot_input, _iodata}, :closed, _data) do
      :keep_state_and_data
    end
    def handle_event(:info, {:vex_robot_input, iodata}, :open, data = %Data{ uart: uart }) do
      :ok = @events.frame_in(iodata)
      # require Logger
      # Logger.info("writing #{inspect iodata} to uart for #{inspect data.device}")
      case Nerves.UART.write(uart, iodata) do
        :ok ->
          :keep_state_and_data
        _ ->
          _ = Nerves.UART.close(uart)
          {:next_state, :closed, data}
      end
    end
    def handle_event(:info, {:nerves_uart, _, _}, :closed, _data) do
      :keep_state_and_data
    end
    def handle_event(:info, {:nerves_uart, _, {:error, _reason}}, :open, data = %Data{ uart: uart }) do
      _ = Nerves.UART.close(uart)
      {:next_state, :closed, data}
    end
    def handle_event(:info, {:nerves_uart, device, iodata}, :open, _data = %Data{ device: device }) do
      :ok = @events.frame_out(iodata)
      # require Logger
      # Logger.info("reading #{inspect iodata} to uart for #{inspect device}")
      :ok = Vex.Robot.IO.output(iodata)
      :keep_state_and_data
    end

  end

end
