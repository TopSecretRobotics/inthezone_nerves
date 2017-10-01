defmodule Vex.Local.Server do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]
  use Bitwise

  @heartbeat 2500
  @deadtimer 5000
  @network_ipv4 5000

  @events Vex.Local.Server.Events
  @socket Vex.Local.Server.Socket
  @socket_events Vex.Local.Server.Socket.Events
  @state Vex.Local.Server.State
  # @subscription Vex.Local.Server.Subscription

  def start_link() do
    GenStateMachine.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def connected?() do
    @socket.connected?()
  end

  def read(read_message, timeout \\ 5000)
  def read(read_message, timeout) do
    iodata = Vex.Frame.encode(read_message)
    with {:ok, read_frame = %Vex.Frame.READ{}} <- Vex.Frame.decode(iodata) do
      GenStateMachine.call(__MODULE__, {:read, read_frame}, timeout)
    else _ ->
      :error
    end
  end

  def subscribe(subscribe_message, timeout \\ 5000)
  def subscribe(subscribe_message, timeout) do
    iodata = Vex.Frame.encode(subscribe_message)
    with {:ok, subscribe_frame = %Vex.Frame.SUBSCRIBE{}} <- Vex.Frame.decode(iodata) do
      GenStateMachine.call(__MODULE__, {:subscribe, :erlang.self(), subscribe_frame}, timeout)
    else _ ->
      :error
    end
  end

  def unsubscribe(unsubscribe_frame = %Vex.Frame.UNSUBSCRIBE{}) do
    vex_rpc_recv(unsubscribe_frame)
  end

  def unsubscribe(subscription, timeout \\ 5000)
  def unsubscribe(unsubscribe_frame = %Vex.Frame.UNSUBSCRIBE{}, _timeout) do
    vex_rpc_recv(unsubscribe_frame)
  end
  def unsubscribe(reference, timeout) when is_reference(reference) do
    GenStateMachine.call(__MODULE__, {:unsubscribe, reference}, timeout)
  end

  def vex_rpc_recv(frame) do
    GenStateMachine.cast(__MODULE__, {:vex_rpc_recv, frame})
  end

  def vex_rpc_send(frame) do
    iodata = Vex.Frame.encode(frame)
    {:ok, frame_out} = Vex.Frame.decode(iodata)
    :ok = @events.frame_out(frame_out)
    @socket.write(iodata)
  end

  defmodule Data do
    defstruct [
      reads: %{},
      subs: %{},
      monitor_map: nil,
      seq_id: 0
    ]
  end

  alias __MODULE__.Data, as: Data

  defmodule Read do
    defstruct [
      from: nil,
      frames: []
    ]
  end

  alias __MODULE__.Read, as: Read

  defmodule Sub do
    defstruct [
      from: nil
    ]
  end

  alias __MODULE__.Sub, as: Sub

  @impl GenStateMachine
  def init([]) do
    data = %Data{
      monitor_map: Vex.MonitorMap.new(__MODULE__)
    }
    :ok = @socket_events.subscribe_status()
    state =
      if @socket.connected?() do
        # :ok = @subscription.connected()
        :ok = @events.connected()
        :connected
      else
        # :ok = @subscription.disconnected()
        :ok = @events.disconnected()
        :disconnected
      end
    {:ok, state, data}
  end

  @impl GenStateMachine
  # State Enter Events
  def handle_event(:enter, old_state, :connected, data) do
    data =
      if old_state == :disconnected do
        :ok = @state.reset_ticks()
        # :ok = @subscription.connected()
        :ok = @events.connected()
        flush_calls(%{ data | seq_id: 0 })
      else
        data
      end
    actions = [
      {:state_timeout, @deadtimer, :deadtimer},
      {{:timeout, :heartbeat}, 0, :send},
      {{:timeout, :network_ipv4}, 0, :send}
    ]
    {:keep_state, data, actions}
  end
  def handle_event(:enter, old_state, :disconnected, data) do
    :ok = @state.reset_ticks()
    if old_state != :disconnected do
      # :ok = @subscription.disconnected()
      :ok = @events.disconnected()
    end
    {:keep_state, flush_calls(%{ data | seq_id: 0 })}
  end
  # State Timeout Events
  def handle_event(:state_timeout, :deadtimer, :connected, data) do
    :ok = @socket.disconnect()
    {:next_state, :disconnected, data}
  end
  # Generic Timeout Events
  def handle_event({:timeout, :heartbeat}, :send, :connected, _data = %Data{ seq_id: seq_id }) do
    :ok = vex_rpc_send(Vex.Frame.ping(seq_id))
    actions = [
      {{:timeout, :heartbeat}, @heartbeat, :send}
    ]
    {:keep_state_and_data, actions}
  end
  def handle_event({:timeout, :network_ipv4}, :send, :connected, _data) do
    << a, b, c, d >> = Vex.Util.ipv4()
    info_message = Vex.Message.Info.Network.Ipv4.new({a, b, c, d})
    :ok = vex_rpc_send(info_message)
    actions = [
      {{:timeout, :network_ipv4}, @network_ipv4, :send}
    ]
    {:keep_state_and_data, actions}
  end
  def handle_event({:timeout, name}, :send, :disconnected, _data) when name in [:heartbeat, :network_ipv4] do
    :keep_state_and_data
  end
  # Call Events
  def handle_event({:call, from}, {:read, frame = %Vex.Frame.READ{ req_id: req_id }}, state, data = %Data{ reads: reads }) when state != :disconnected do
    with false <- Map.has_key?(reads, req_id),
         :ok <- vex_rpc_send(frame) do
      read = %Read{ from: from }
      data = %{ data | reads: Map.put(reads, req_id, read) }
      {:keep_state, data}
    else _ ->
      {:keep_state_and_data, [{:reply, from, :error}]}
    end
  end
  def handle_event({:call, from}, {:subscribe, to, frame = %Vex.Frame.SUBSCRIBE{ req_id: req_id }}, state, data = %Data{ subs: subs, monitor_map: monitor_map }) when state != :disconnected do
    with false <- Map.has_key?(subs, req_id),
         :ok <- vex_rpc_send(frame) do
      tag = :erlang.make_ref()
      sub = %Sub{ from: {to, tag} }
      data = %{ data | subs: Map.put(subs, req_id, sub), monitor_map: Vex.MonitorMap.up(monitor_map, req_id, to) }
      {:keep_state, data, [{:reply, from, {:ok, tag}}]}
    else _ ->
      {:keep_state_and_data, [{:reply, from, :error}]}
    end
  end
  def handle_event({:call, from}, {:unsubscribe, reference}, state, data = %Data{ subs: subs }) when state != :disconnected and is_reference(reference) do
    :ok = unsubscribe_by_ref(Map.to_list(subs), reference)
    {:keep_state, data, [{:reply, from, :ok}]}
  end
  def handle_event({:call, from}, _request, :disconnected, _data) do
    {:keep_state_and_data, [{:reply, from, :error}]}
  end
  # Cast Events
  def handle_event(:cast, {:vex_rpc_recv, frame}, state, data) when state != :disconnected do
    :ok = @events.frame_in(frame)
    actions = [
      {:state_timeout, @deadtimer, :deadtimer}
    ]
    case rpc_recv(data, frame) do
      :keep_state_and_data ->
        {:keep_state_and_data, actions}
      {:keep_state, data} ->
        {:keep_state, data, actions}
      {:keep_state, data, new_actions} ->
        {:keep_state, data, new_actions ++ actions}
      other ->
        other
    end
  end
  def handle_event(:cast, {:vex_rpc_recv, _frame}, :disconnected, _data) do
    :keep_state_and_data
  end
  # Info Events
  def handle_event(:info, {@socket, :status, :connected}, :disconnected, data) do
    {:next_state, :connected, data}
  end
  def handle_event(:info, {@socket, :status, :disconnected}, state, data) when state != :disconnected do
    {:next_state, :disconnected, data}
  end
  def handle_event(:info, {@socket, :status, event}, _state, _data) when event in [:connected, :disconnected] do
    :keep_state_and_data
  end
  def handle_event(:info, {:DOWN, monitor_ref, :process, pid, _reason}, _state, data = %Data{ subs: subs, monitor_map: monitor_map }) do
    monitor_map = Vex.MonitorMap.down(monitor_map, monitor_ref, pid)
    :ok = unsubscribe_by_pid(Map.to_list(subs), pid)
    data = %{ data | monitor_map: monitor_map }
    {:keep_state, data}
  end

  @doc false
  defp flush_calls(data = %Data{ reads: reads, subs: subs, monitor_map: monitor_map }) do
    read_replies =
      for %Read{ from: from } <- Map.values(reads), into: [] do
        {:reply, from, :error}
      end
    _ = GenStateMachine.reply(read_replies)
    subscribe_replies =
      for %Sub{ from: from } <- Map.values(subs), into: [] do
        {:reply, from, :error}
      end
    _ = GenStateMachine.reply(subscribe_replies)
    %{ data | reads: %{}, subs: %{}, monitor_map: Vex.MonitorMap.delete(monitor_map) }
  end

  @doc false
  defp unsubscribe_by_pid([{req_id, %Sub{ from: {pid, _} }} | _], pid) do
    unsubscribe_frame = Vex.Frame.unsubscribe(req_id)
    :ok = vex_rpc_send(unsubscribe_frame)
    :ok
  end
  defp unsubscribe_by_pid([_ | rest], pid) do
    unsubscribe_by_pid(rest, pid)
  end
  defp unsubscribe_by_pid([], _pid) do
    :ok
  end

  @doc false
  defp unsubscribe_by_ref([{req_id, %Sub{ from: {_, ref} }} | _], ref) do
    unsubscribe_frame = Vex.Frame.unsubscribe(req_id)
    :ok = vex_rpc_send(unsubscribe_frame)
    :ok
  end
  defp unsubscribe_by_ref([_ | rest], ref) do
    unsubscribe_by_ref(rest, ref)
  end
  defp unsubscribe_by_ref([], _ref) do
    :ok
  end

  @doc false
  defp rpc_recv(data, frame) do
    case frame do
      %Vex.Frame.PING{} ->
        rpc_recv_ping(data, frame)
      %Vex.Frame.PONG{} ->
        rpc_recv_pong(data, frame)
      %Vex.Frame.INFO{} ->
        :keep_state_and_data
      %Vex.Frame.DATA{} ->
        rpc_recv_data(data, frame)
      %Vex.Frame.READ{} ->
        # rpc_recv_read(data, frame)
        :keep_state_and_data
      %Vex.Frame.WRITE{} ->
        # rpc_recv_write(data, frame)
        :keep_state_and_data
      %Vex.Frame.SUBSCRIBE{} ->
        # rpc_recv_subscribe(data, frame)
        :keep_state_and_data
      %Vex.Frame.UNSUBSCRIBE{} ->
        # rpc_recv_unsubscribe(data, frame)
        :keep_state_and_data
      _ ->
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_ping(data, ping_frame) do
    data = %{ data | seq_id: ping_frame.seq_id }
    pong_frame = Vex.Frame.pong(ping_frame.seq_id)
    :ok = vex_rpc_send(pong_frame)
    {:keep_state, data}
  end

  @doc false
  defp rpc_recv_pong(data = %{ seq_id: seq_id }, _pong_frame = %{ seq_id: seq_id }) do
    # require Logger
    # Logger.info("got a pong: #{inspect seq_id}")
    data = %{ data | seq_id: (seq_id + 1) &&& 0xff }
    {:keep_state, data}
    # {:next_state, :connected, data}
  end
  defp rpc_recv_pong(_data, _pong_frame) do
    # require Logger
    # Logger.info("bad pong: #{inspect _pong_frame}")
    :keep_state_and_data
  end

  @doc false
  defp rpc_recv_data(data = %{ reads: reads, subs: subs, monitor_map: monitor_map }, data_frame = %{ req_id: req_id }) do
    case data_frame.flag do
      %{ pub: true, end: true, error: is_error } ->
        case :maps.take(req_id, subs) do
          {%Sub{ from: from }, subs} ->
            data = %{ data | subs: subs, monitor_map: Vex.MonitorMap.delete_by_ref(monitor_map, req_id) }
            replies = [{:reply, from, :end}]
            replies =
              if is_error do
                [{:reply, from, {:error, data_frame}} | replies]
              else
                [{:reply, from, {:data, data_frame}} | replies]
              end
            :ok = GenStateMachine.reply(replies)
            {:keep_state, data}
          :error ->
            :keep_state_and_data
        end
      %{ pub: true, end: false, error: false } ->
        case Map.fetch(subs, req_id) do
          {:ok, %Sub{ from: from }} ->
            replies = [{:reply, from, {:data, data_frame}}]
            :ok = GenStateMachine.reply(replies)
            :keep_state_and_data
          :error ->
            :ok = vex_rpc_send(Vex.Frame.unsubscribe(req_id))
            :keep_state_and_data
        end
      %{ pub: false, end: true, error: is_error } ->
        case :maps.take(req_id, reads) do
          {%Read{ from: from, frames: frames }, reads} ->
            data = %{ data | reads: reads }
            frames =
              if is_error do
                [:end, {:error, data_frame} | frames]
              else
                [:end, {:data, data_frame} | frames]
              end
            frames = :lists.reverse(frames)
            replies = [{:reply, from, {:ok, frames}}]
            :ok = GenStateMachine.reply(replies)
            {:keep_state, data}
          :error ->
            :keep_state_and_data
        end
      %{ pub: false, end: false, error: false } ->
        case Map.fetch(reads, req_id) do
          {:ok, read = %Read{ frames: frames }} ->
            frames = [{:data, data_frame} | frames]
            read = %{ read | frames: frames }
            reads = Map.put(reads, req_id, read)
            data = %{ data | reads: reads }
            {:keep_state, data}
          :error ->
            :keep_state_and_data
        end
    end
  end

  # @doc false
  # defp rpc_recv_read(data, read) do
  #   case read.topic do
  #     @topic_network ->
  #       rpc_recv_read_network(data, read)
  #     @topic_clock ->
  #       rpc_recv_read_clock(data, read)
  #     @topic_motor ->
  #       rpc_recv_read_motor(data, read)
  #     _ ->
  #       _ = rpc_send_req_error(data, read.req_id, read.topic, read.subtopic, @error_bad_topic)
  #       :keep_state_and_data
  #   end
  # end

end
