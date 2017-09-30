defmodule Vex.Robot.IO do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def can_input?() do
    output_pid = :erlang.self()
    with {:ok, ^output_pid} <- fetch_output() do
      true
    else _ ->
      false
    end
  end

  def can_output?() do
    input_pid = :erlang.self()
    with {:ok, ^input_pid} <- fetch_input() do
      true
    else _ ->
      false
    end
  end

  def input(iodata) do
    GenServer.cast(__MODULE__, {:input, :erlang.self(), iodata})
  end

  def output(iodata) do
    GenServer.cast(__MODULE__, {:output, :erlang.self(), iodata})
  end

  def fetch_input() do
    GenServer.call(__MODULE__, :fetch_input, :infinity)
  end

  def fetch_output() do
    GenServer.call(__MODULE__, :fetch_output, :infinity)
  end

  def list_input() do
    GenServer.call(__MODULE__, :list_input, :infinity)
  end

  def list_output() do
    GenServer.call(__MODULE__, :list_output, :infinity)
  end

  def register_input(priority, pid) when is_integer(priority) and is_pid(pid) do
    GenServer.call(__MODULE__, {:register_input, priority, pid}, :infinity)
  end

  def register_output(priority, pid) when is_integer(priority) and is_pid(pid) do
    GenServer.call(__MODULE__, {:register_output, priority, pid}, :infinity)
  end

  def unregister_input(priority, pid) when is_integer(priority) and is_pid(pid) do
    GenServer.call(__MODULE__, {:unregister_input, priority, pid}, :infinity)
  end

  def unregister_output(priority, pid) when is_integer(priority) and is_pid(pid) do
    GenServer.call(__MODULE__, {:unregister_output, priority, pid}, :infinity)
  end

  defmodule State do
    defstruct [
      input: nil,
      output: nil
    ]
  end

  alias __MODULE__.State, as: State

  @impl GenServer
  def init([]) do
    state = %State{
      input: Vex.PriorityMap.new(:input),
      output: Vex.PriorityMap.new(:output)
    }
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:fetch_input, _from, state = %State{ input: input }) do
    result = Vex.PriorityMap.highest(input)
    {:reply, result, state}
  end
  def handle_call(:fetch_output, _from, state = %State{ output: output }) do
    result = Vex.PriorityMap.highest(output)
    {:reply, result, state}
  end
  def handle_call(:list_input, _from, state = %State{ input: input }) do
    result = Vex.PriorityMap.to_list(input)
    {:reply, result, state}
  end
  def handle_call(:list_output, _from, state = %State{ output: output }) do
    result = Vex.PriorityMap.to_list(output)
    {:reply, result, state}
  end
  def handle_call({:register_input, priority, pid}, _from, state = %State{ input: input }) do
    input = Vex.PriorityMap.up(input, priority, pid)
    state = %{ state | input: input }
    {:reply, true, state}
  end
  def handle_call({:register_output, priority, pid}, _from, state = %State{ output: output }) do
    output = Vex.PriorityMap.up(output, priority, pid)
    state = %{ state | output: output }
    {:reply, true, state}
  end
  def handle_call({:unregister_input, priority, pid}, _from, state = %State{ input: input }) do
    input = Vex.PriorityMap.delete(input, priority, pid)
    state = %{ state | input: input }
    {:reply, true, state}
  end
  def handle_call({:unregister_output, priority, pid}, _from, state = %State{ output: output }) do
    output = Vex.PriorityMap.delete(output, priority, pid)
    state = %{ state | output: output }
    {:reply, true, state}
  end

  @impl GenServer
  def handle_cast({:input, output_pid, iodata}, state = %State{ input: input, output: output }) do
    with {:ok, ^output_pid} <- Vex.PriorityMap.highest(output),
         {:ok, input_pid} <- Vex.PriorityMap.highest(input) do
      _ = :erlang.send(input_pid, {:vex_robot_input, iodata})
      {:noreply, state}
    else _ ->
      # require Logger
      # Logger.info("ignoring input: #{inspect iodata}")
      {:noreply, state}
    end
  end
  def handle_cast({:output, input_pid, iodata}, state = %State{ input: input, output: output }) do
    with {:ok, ^input_pid} <- Vex.PriorityMap.highest(input),
         {:ok, output_pid} <- Vex.PriorityMap.highest(output) do
      _ = :erlang.send(output_pid, {:vex_robot_output, iodata})
      {:noreply, state}
    else _ ->
      # require Logger
      # Logger.info("ignoring output: #{inspect iodata}")
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, monitor_ref, :process, pid, _reason}, state = %State{ input: input, output: output }) do
    input = Vex.PriorityMap.down(input, monitor_ref, pid)
    output = Vex.PriorityMap.down(output, monitor_ref, pid)
    state = %{ state | input: input, output: output }
    {:noreply, state}
  end

end