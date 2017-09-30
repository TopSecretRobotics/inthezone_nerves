defmodule Ui.Vex.Debug do
  use GenServer
  use Bitwise

  @local_server Vex.Local.Server
  @local_socket Vex.Local.Server.Socket
  @robot_server Vex.Robot.Server
  @robot_socket Vex.Robot.Server.Socket

  @local_server_events Vex.Local.Server.Events
  @local_socket_events Vex.Local.Server.Socket.Events
  @robot_server_events Vex.Robot.Server.Events
  @robot_socket_events Vex.Robot.Server.Socket.Events

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def flush() do
    GenServer.call(__MODULE__, :flush, :infinity)
  end

  def flush(key) do
    GenServer.call(__MODULE__, {:flush, key}, :infinity)
  end

  def head(key) do
    GenServer.call(__MODULE__, {:head, key}, :infinity)
  end

  defmodule State do
    @capacity 1000

    defstruct [
      counter: 0,
      evref: nil,
      events: %{
        local_server: :queue.new(),
        local_socket: :queue.new(),
        robot_server: :queue.new(),
        robot_socket: :queue.new()
      },
      local_server: Vex.Buffer.new(:queue, @capacity),
      local_socket: Vex.Buffer.new(:queue, @capacity),
      robot_server: Vex.Buffer.new(:queue, @capacity),
      robot_socket: Vex.Buffer.new(:queue, @capacity)
    ]
  end

  alias __MODULE__.State, as: State

  @impl GenServer
  def init([]) do
    :ok = @local_server_events.subscribe_all()
    :ok = @local_socket_events.subscribe_all()
    :ok = @robot_server_events.subscribe_all()
    :ok = @robot_socket_events.subscribe_all()
    state = %State{}
    event = %Ui.Events.Status{
      id: state.counter,
      source: @local_server,
      connected: @local_server.connected?()
    }
    state = source_input(state, @local_server, event)
    event = %Ui.Events.Status{
      id: state.counter,
      source: @local_socket,
      connected: @local_socket.connected?()
    }
    state = source_input(state, @local_socket, event)
    event = %Ui.Events.Status{
      id: state.counter,
      source: @robot_server,
      connected: @robot_server.connected?()
    }
    state = source_input(state, @robot_server, event)
    event = %Ui.Events.Status{
      id: state.counter,
      source: @robot_socket,
      connected: @robot_socket.connected?()
    }
    state = source_input(state, @robot_socket, event)
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:flush, _from, state) do
    {:ok, buffers, state} = flush_buffers(Map.to_list(state), %{}, state)
    {:reply, buffers, state}
  end
  def handle_call({:flush, key}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, buffer = %Vex.Buffer{}} ->
        {:ok, flush, buffer} = Vex.Buffer.flush(buffer)
        state = :maps.update(key, buffer, state)
        {:reply, {:ok, flush}, state}
      _ ->
        {:reply, :error, state}
    end
  end
  def handle_call({:head, key}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, buffer = %Vex.Buffer{}} ->
        head = Vex.Buffer.to_list(buffer)
        {:reply, {:ok, head}, state}
      _ ->
        {:reply, :error, state}
    end
  end

  @impl GenServer
  def handle_info({source, :status, event}, state) when source in [@local_server, @local_socket, @robot_server, @robot_socket] and event in [:connected, :disconnected] do
    struct = %Ui.Events.Status{
      id: state.counter,
      source: source,
      connected: (if event == :connected, do: true, else: false)
    }
    state = source_input(state, source, struct)
    {:noreply, state}
  end
  def handle_info({source, :frame, {event, frame}}, state) when source in [@local_server, @local_socket, @robot_server, @robot_socket] and event in [:in, :out] do
    struct = Ui.Events.Frame.new(state.counter, source, event, frame)
    state = source_input(state, source, struct)
    {:noreply, state}
  end
  def handle_info({:timeout, evref, :send_events}, state = %State{ evref: evref }) do
    state = %{ state | evref: nil }
    state = flush_events(state)
    {:noreply, state}
  end

  @doc false
  defp flush_buffers([{key, buffer = %Vex.Buffer{}} | rest], acc, state) do
    {:ok, flush, buffer} = Vex.Buffer.flush(buffer)
    acc = Map.put(acc, key, flush)
    state = :maps.update(key, buffer, state)
    flush_buffers(rest, acc, state)
  end
  defp flush_buffers([_ | rest], acc, state) do
    flush_buffers(rest, acc, state)
  end
  defp flush_buffers([], acc, state) do
    {:ok, acc, state}
  end

  @doc false
  defp flush_events(state = %State{ events: events }) do
    flush_events(state, Map.to_list(events))
  end

  @doc false
  defp flush_events(state = %{ events: events }, [{key, queue} | rest]) do
    case :queue.to_list(queue) do
      [] ->
        flush_events(state, rest)
      list ->
        subscription_key = String.to_atom("observe_#{key}_events")
        :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, list, [{subscription_key, <<>>}])
        state = %{ state | events: Map.put(events, key, :queue.new()) }
        flush_events(state, rest)
    end
  end
  defp flush_events(state, []) do
    state
  end

  @doc false
  defp maybe_start_timer(state = %State{ evref: nil }) do
    evref = :erlang.start_timer(250, :erlang.self(), :send_events)
    %{ state | evref: evref }
  end
  defp maybe_start_timer(state = %State{}) do
    state
  end

  @doc false
  defp source_input(state = %State{ counter: counter, events: events }, source, item) do
    {key, buffer} = source_to_buffer(state, source)
    buffer = Vex.Buffer.input!(buffer, item)
    counter = (counter + 1) &&& 0xffffffffffffffff
    events = :maps.update(key, :queue.in(item, Map.fetch!(events, key)), events)
    state = maybe_start_timer(%{ state | counter: counter, events: events })
    :maps.update(key, buffer, state)
  end

  @doc false
  defp source_to_buffer(%State{ local_server: buf }, @local_server), do: {:local_server, buf}
  defp source_to_buffer(%State{ local_socket: buf }, @local_socket), do: {:local_socket, buf}
  defp source_to_buffer(%State{ robot_server: buf }, @robot_server), do: {:robot_server, buf}
  defp source_to_buffer(%State{ robot_socket: buf }, @robot_socket), do: {:robot_socket, buf}
end