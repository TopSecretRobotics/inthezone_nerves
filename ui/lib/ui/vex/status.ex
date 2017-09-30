defmodule Ui.Vex.Status do
  use GenServer
  use Bitwise

  @local_server Vex.Local.Server

  @local_server_events Vex.Local.Server.Events

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def connected?() do
    GenServer.call(__MODULE__, :is_connected, :infinity)
  end

  def batteries() do
    GenServer.call(__MODULE__, :batteries, :infinity)
  end

  def ticks() do
    GenServer.call(__MODULE__, :ticks, :infinity)
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
      connected: false,
      ticks: 0,
      main_battery: 0,
      backup_battery: 0,
      counter: 0,
      evref: nil,
      events: :queue.new(),
      buffer: Vex.Buffer.new(:queue, @capacity)
    ]
  end

  alias __MODULE__.State, as: State

  @impl GenServer
  def init([]) do
    :ok = @local_server_events.subscribe_all()
    connected = @local_server.connected?()
    state = %State{
      connected: connected,
      main_battery: 0,
      backup_battery: 0
    }
    event = %Ui.Events.Status{
      id: state.counter,
      source: @local_server,
      connected: connected
    }
    state = source_input(state, event)
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:is_connected, _from, state = %State{ connected: connected }) do
    {:reply, connected, state}
  end
  def handle_call(:batteries, _from, state = %State{ main_battery: main_battery, backup_battery: backup_battery }) do
    {:reply, %{ main: main_battery / 1000.0, backup: backup_battery / 1000.0 }, state}
  end
  def handle_call(:ticks, _from, state = %State{ ticks: ticks }) do
    {:reply, ticks, state}
  end
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
  def handle_info({source, :status, event}, state) when source in [@local_server] and event in [:connected, :disconnected] do
    struct = %Ui.Events.Status{
      id: state.counter,
      source: source,
      connected: (if event == :connected, do: true, else: false)
    }
    state =
      if event == :connected do
        %{ state | connected: true }
      else
        %{ state | connected: false, ticks: 0, main_battery: 0, backup_battery: 0 }
      end
    state = source_input(state, struct)
    {:noreply, state}
  end
  def handle_info({source, :frame, {:in, info_frame = %Vex.Frame.INFO{}}}, state = %State{ ticks: old_ticks, main_battery: old_main_battery, backup_battery: old_backup_battery }) when source in [@local_server] do
    # require Logger
    # Logger.info("info frame: #{inspect info_frame}")
    case Vex.Message.decode(info_frame) do
      {:ok, frame = %Vex.Message.Info.Robot.Spi{ value: {ticks, main_battery, backup_battery} }} ->
        # Logger.info("info frame: #{inspect frame}")
        if ticks != old_ticks do
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, ticks, [{:observe_ticks, <<>>}])
        end
        if main_battery != old_main_battery do
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, main_battery / 1000.0, [{:observe_main_battery, <<>>}])
        end
        if backup_battery != old_backup_battery do
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, backup_battery / 1000.0, [{:observe_backup_battery, <<>>}])
        end
        state = %{ state | ticks: ticks, main_battery: main_battery, backup_battery: backup_battery }
        {:noreply, state}
      _ ->
        {:noreply, state}
    end
  end
  def handle_info({source, :frame, {event, _}}, state) when source in [@local_server] and event in [:in, :out] do
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
  defp flush_events(state = %State{ events: queue }) do
    :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, state.connected, [{:observe_is_connected, <<>>}])
    case :queue.to_list(queue) do
      [] ->
        state
      list ->
        :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, list, [{:observe_status_events, <<>>}])
        state = %{ state | events: :queue.new() }
        state
    end
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
  defp source_input(state = %State{ counter: counter, events: events, buffer: buffer }, item) do
    buffer = Vex.Buffer.input!(buffer, item)
    counter = (counter + 1) &&& 0xffffffffffffffff
    events = :queue.in(item, events)
    state = maybe_start_timer(%{ state | counter: counter, events: events, buffer: buffer })
    state
  end
end