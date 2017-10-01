defmodule Vex.State.Autostart do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @maybe_stop 1000

  def start_link() do
    GenStateMachine.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def subscribe(module, pid) when is_atom(module) and is_pid(pid) do
    with {:ok, _} <- Vex.State.Supervisor.maybe_start_child(module) do
      GenStateMachine.call(__MODULE__, {:subscribe, module, pid})
    end
  end

  def unsubscribe(module, pid) when is_atom(module) and is_pid(pid) do
    GenStateMachine.call(__MODULE__, {:unsubscribe, module, pid})
  end

  defmodule Child do
    defstruct [
      counters: %{},
      monitors: %{}
    ]

    def empty?(%Child{ counters: counters, monitors: monitors }) when map_size(counters) == 0 and map_size(monitors) == 0 do
      true
    end
    def empty?(%Child{}) do
      false
    end
  end

  alias __MODULE__.Child, as: Child

  defmodule Data do
    defstruct [
      children: %{}
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    data = %Data{}
    {:ok, nil, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, nil, nil, _data) do
    :keep_state_and_data
  end
  # Generic Timeout Events
  def handle_event({:timeout, module}, :soft_stop, _state, _data = %Data{ children: children }) do
    case Map.fetch(children, module) do
      {:ok, child} ->
        if Child.empty?(child) do
          actions = [{{:timeout, module}, @maybe_stop, :hard_stop}]
          {:keep_state_and_data, actions}
        else
          :keep_state_and_data
        end
      :error ->
        :keep_state_and_data
    end
  end
  def handle_event({:timeout, module}, :hard_stop, _state, data = %Data{ children: children }) do
    case Map.fetch(children, module) do
      {:ok, child} ->
        if Child.empty?(child) do
          :ok = module.stop()
          children = Map.delete(children, module)
          data = %{ data | children: children }
          {:keep_state, data}
        else
          :keep_state_and_data
        end
      :error ->
        :keep_state_and_data
    end
  end
  # Call Evnets
  def handle_event({:call, from}, {:subscribe, module, pid}, _state, data = %Data{ children: children }) do
    :ok = module.subscribe(pid)
    child = %Child{ counters: counters, monitors: monitors } = Map.get(children, module, %Child{})
    counter = Map.get(counters, pid, 0)
    counters = Map.put(counters, pid, counter + 1)
    monitors =
      if Map.has_key?(monitors, pid) do
        monitors
      else
        monitor = :erlang.monitor(:process, pid)
        Map.put(monitors, pid, monitor)
      end
    child = %{ child | counters: counters, monitors: monitors }
    children = Map.put(children, module, child)
    data = %{ data | children: children }
    actions = [{:reply, from, :ok}, {{:timeout, module}, :infinity, :ignore}]
    {:keep_state, data, actions}
  end
  def handle_event({:call, from}, {:unsubscribe, module, pid}, _state, data = %Data{ children: children }) do
    child = %Child{ counters: counters, monitors: monitors } = Map.get(children, module, %Child{})
    counter = Map.get(counters, pid, 1)
    counters =
      if counter == 1 do
        Map.delete(counters, pid)
      else
        Map.put(counters, pid, counter - 1)
      end
    monitors =
      if counter == 1 do
        case :maps.take(pid, monitors) do
          {monitor, new_monitors} ->
            _ = :erlang.demonitor(monitor, [:flush])
            new_monitors
          :error ->
            monitors
        end
      else
        monitors
      end
    child = %{ child | counters: counters, monitors: monitors }
    children = Map.put(children, module, child)
    data = %{ data | children: children }
    actions = [{:reply, from, :ok}, {{:timeout, module}, @maybe_stop, :soft_stop}]
    {:keep_state, data, actions}
  end
  # Info Events
  def handle_event(:info, {:DOWN, _monitor, :process, pid, _reason}, _state, data = %Data{ children: children }) do
    handle_down(Map.to_list(children), pid, data, [])
  end

  @doc false
  defp handle_down([{module, child = %Child{ counters: counters, monitors: monitors }} | rest], pid, data = %Data{ children: children }, actions) do
    if Map.has_key?(counters, pid) or Map.has_key?(monitors, pid) do
      counters = Map.delete(counters, pid)
      monitors = Map.delete(monitors, pid)
      child = %{ child | counters: counters, monitors: monitors }
      children = Map.put(children, module, child)
      data = %{ data | children: children }
      actions = [{{:timeout, module}, @maybe_stop, :soft_stop} | actions]
      handle_down(rest, pid, data, actions)
    else
      handle_down(rest, pid, data, actions)
    end
  end
  defp handle_down([], _pid, data, actions) do
    {:keep_state, data, actions}
  end

  # @impl GenStateMachine
  # def terminate(_reason, :connected, _data = %Data{ subscription: subscription }) do
  #   require Logger
  #   Logger.info("UNSUBSCRIBING SUBSCRIBER")
  #   _ = Vex.RPC.unsubscribe(subscription)
  #   :ok
  # end
  # def terminate(_reason, _state, _data) do
  #   require Logger
  #   Logger.info("STOPPING SUBSCRIBER")
  #   :ok
  # end

end