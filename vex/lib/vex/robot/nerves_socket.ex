if Code.ensure_loaded?(Nerves.UART) do

  defmodule Vex.Robot.NervesSocket do
    use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

    @priority 100
    @reopen 1000
    @wait 2

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
        uart: nil,
        uart_buffer: <<>>,
        uart_wait: false,
        vex_buffer: <<>>,
        vex_wait: false
      ]
    end

    alias __MODULE__.Data, as: Data

    @impl GenStateMachine
    def init([]) do
      true = Vex.Robot.IO.register_input(@priority, :erlang.self())
      device = Application.get_env(:vex, :nerves_socket_device, "ttyS0")
      options = Application.get_env(:vex, :nerves_socket_device_options, [
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
        {:next_state, :open, data}
      else _ ->
        {:keep_state_and_data, [{:state_timeout, @reopen, :open}]}
      end
    end
    # Generic Timeout Events
    def handle_event({:timeout, :uart}, :wait, :open, data = %{ uart: uart, uart_buffer: iodata, uart_wait: true }) do
      data = %{ data | uart_buffer: <<>>, uart_wait: false }
      :ok = @events.frame_out(iodata)
      :ok = Vex.Robot.IO.output(iodata)
      :ok = @uart.configure(uart, active: true)
      {:keep_state, data}
    end
    def handle_event({:timeout, :vex}, :wait, :open, data = %{ vex_buffer: iodata, vex_wait: true, uart: uart }) do
      data = %{ data | vex_buffer: <<>>, vex_wait: false }
      :ok = @events.frame_in(iodata)
      with :ok <- @uart.write(uart, iodata),
           :ok <- @uart.drain(uart) do
        {:keep_state, data}
      else _ ->
        data = cleanup(data)
        {:next_state, :closed, data}
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
      actions = [{:reply, from, reply}]
      {:keep_state_and_data, actions}
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
    defp cleanup(data = %{ uart: uart }) do
      _ = @uart.close(uart)
      %{ data | uart_buffer: <<>>, uart_wait: false, vex_buffer: <<>>, vex_wait: false }
    end

  end

end
