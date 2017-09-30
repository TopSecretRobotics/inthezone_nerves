defmodule Vex.Robot.Server do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]
  use Bitwise

  # @publish 5000
  @publish 25

  @events Vex.Robot.Server.Events
  @socket Vex.Robot.Server.Socket
  @socket_events Vex.Robot.Server.Socket.Events
  @state Vex.Robot.Server.State

  def start_link() do
    GenStateMachine.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def connected?() do
    @socket.connected?()
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

  defmodule Sub do
    defstruct [
      active: false,
      req_id: 0,
      topic: 0,
      subtopic: 0
    ]
  end

  alias __MODULE__.Sub, as: Sub

  defmodule Data do
    defstruct [
      seq_id: 0,
      ipv4: 0,
      heartbeat: nil,
      motors: %{
        0 => 0,
        1 => 0,
        2 => 0,
        3 => 0,
        4 => 0,
        5 => 0,
        6 => 0,
        7 => 0,
        8 => 0,
        9 => 0
      },
      subs: %{
        0 => %Sub{},
        1 => %Sub{},
        2 => %Sub{},
        3 => %Sub{},
        4 => %Sub{},
        5 => %Sub{},
        6 => %Sub{},
        7 => %Sub{},
        8 => %Sub{},
        9 => %Sub{}
      }
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenStateMachine
  def init([]) do
    data = %Data{
      heartbeat: :os.system_time(:millisecond)
    }
    :ok = @socket_events.subscribe_status()
    state =
      if @socket.connected?() do
        :ok = @events.connected()
        :connected
      else
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
        :ok = @events.connected()
        %{ data | seq_id: 0 }
      else
        data
      end
    {:keep_state, data}
  end
  def handle_event(:enter, old_state, :disconnected, data) do
    :ok = @state.reset_ticks()
    if old_state != :disconnected do
      :ok = @events.disconnected()
    end
    {:keep_state, %{ data | seq_id: 0 }}
  end
  # State Timeout Events
  def handle_event(:state_timeout, :publish, :connected, data = %Data{ subs: subs }) do
    active_subs =
      for {i, sub = %Sub{ active: true }} <- subs, into: [] do
        {i, sub}
      end
    rpc_publish(data, active_subs)
  end
  # Cast Events
  def handle_event(:cast, {:vex_rpc_recv, frame}, state, data) when state != :disconnected do
    :ok = @events.frame_in(frame)
    rpc_recv(data, frame)
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

  @data_flag_end 0x01
  @data_flag_pub 0x02
  @data_flag_error 0x04

  @error_bad_req_id 0x01
  @error_bad_topic 0x02
  @error_bad_subtopic 0x03
  @error_sub_max 0x04

  @topic_pubsub 0x00
  @topic_pubsub_subtopic_count 0xfb
  @topic_pubsub_subtopic_free 0xfc
  @topic_pubsub_subtopic_max 0xfd
  @topic_pubsub_subtopic_list 0xfe
  @topic_pubsub_subtopic_all 0xff
  @topic_clock 0x01
  @topic_clock_subtopic_now 0x00
  @topic_motor 0x02
  @topic_motor_subtopic_all 0xff
  # @topic_smartmotor 0x03
  # @topic_smartmotor_subtopic_all 0xff
  @topic_network 0x04
  @topic_network_subtopic_ipv4 0x00
  @topic_all 0xff
  @topic_all_subtopic_all 0xff

  @rpc_sub_max 10

  @doc false
  defp rpc_publish(data, [{i, sub} | rest]) do
    case sub.topic do
      @topic_clock ->
        data = rpc_publish_clock(data, {i, sub})
        rpc_publish(data, rest)
      @topic_motor ->
        data = rpc_publish_motor(data, {i, sub})
        rpc_publish(data, rest)
      @topic_all ->
        data = rpc_publish_all(data, {i, sub})
        rpc_publish(data, rest)
      _ ->
        :ok = rpc_send_pub_error(data, sub, @error_bad_topic)
        subs = Map.put(data.subs, i, %Sub{})
        data = %{ data | subs: subs }
        rpc_publish(data, rest)
    end
  end
  defp rpc_publish(data, []) do
    {:keep_state, data, [{:state_timeout, @publish, :publish}]}
  end

  @doc false
  defp rpc_publish_clock(data, {i, sub}) do
    case sub.subtopic do
      @topic_clock_subtopic_now ->
        :ok = rpc_send_pub(data, sub, << (:os.system_time(:millisecond)) :: unsigned-big-integer-unit(1)-size(64) >>)
        data
      _ ->
        :ok = rpc_send_pub_error(data, sub, @error_bad_subtopic)
        subs = Map.put(data.subs, i, %Sub{})
        %{ data | subs: subs }
    end
  end

  @doc false
  defp rpc_publish_motor(data, {i, sub}) do
    case sub.subtopic do
      i when i < 10 ->
        value = Map.fetch!(data.motors, i)
        _ = rpc_send_pub(data, sub, <<
          value :: signed-big-integer-unit(1)-size(8)
        >>)
        data
      @topic_motor_subtopic_all ->
        payload =
          for {index, value} <- data.motors, into: <<>> do
            <<
              index :: signed-big-integer-unit(1)-size(8),
              value :: signed-big-integer-unit(1)-size(8)
            >>
          end
        :ok = rpc_send_pub(data, sub, payload)
        data
      _ ->
        :ok = rpc_send_pub_error(data, sub, @error_bad_subtopic)
        subs = Map.put(data.subs, i, %Sub{})
        %{ data | subs: subs }
    end
  end

  @doc false
  defp rpc_publish_all(data, {i, sub}) do
    case sub.subtopic do
      @topic_all_subtopic_all ->
        data = rpc_publish_clock(data, {i, %{ sub | topic: @topic_clock, subtopic: @topic_clock_subtopic_now }})
        data = rpc_publish_motor(data, {i, %{ sub | topic: @topic_motor, subtopic: @topic_motor_subtopic_all }})
        data
      _ ->
        :ok = rpc_send_pub_error(data, sub, @error_bad_subtopic)
        subs = Map.put(data.subs, i, %Sub{})
        %{ data | subs: subs }
    end
  end

  @doc false
  defp rpc_recv(data, frame) do
    case frame do
      %Vex.Frame.PING{} ->
        rpc_recv_ping(data, frame)
      %Vex.Frame.PONG{} ->
        :keep_state_and_data
      %Vex.Frame.INFO{} ->
        rpc_recv_info(data, frame)
      %Vex.Frame.DATA{} ->
        :keep_state_and_data
      %Vex.Frame.READ{} ->
        rpc_recv_read(data, frame)
      %Vex.Frame.WRITE{} ->
        rpc_recv_write(data, frame)
      %Vex.Frame.SUBSCRIBE{} ->
        rpc_recv_subscribe(data, frame)
      %Vex.Frame.UNSUBSCRIBE{} ->
        rpc_recv_unsubscribe(data, frame)
      _ ->
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_ping(data, ping_frame) do
    data = %{ data | heartbeat: :os.system_time(:millisecond), seq_id: ping_frame.seq_id }
    pong_frame = Vex.Frame.pong(ping_frame.seq_id)
    :ok = rpc_send(data, pong_frame)
    {:keep_state, data}
  end

  @doc false
  defp rpc_recv_info(data, info) do
    case info.topic do
      @topic_network ->
        rpc_recv_info_network(data, info)
      _ ->
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_info_network(data, info) do
    case info.subtopic do
      @topic_network_subtopic_ipv4 ->
        case info.value do
          << value :: unsigned-big-integer-unit(1)-size(32) >> ->
            data = %{ data | ipv4: value }
            {:keep_state, data}
          _ ->
            :keep_state_and_data
        end
      _ ->
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_read(data, read) do
    case read.topic do
      @topic_pubsub ->
        rpc_recv_read_pubsub(data, read)
      @topic_clock ->
        rpc_recv_read_clock(data, read)
      @topic_motor ->
        rpc_recv_read_motor(data, read)
      _ ->
        _ = rpc_send_rep_error(data, read.req_id, read.topic, read.subtopic, @error_bad_topic)
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_read_pubsub(data, read) do
    case read.subtopic do
      i when i < @rpc_sub_max ->
        case Map.fetch(data.subs, i) do
          {:ok, %Sub{ active: true, req_id: req_id, topic: topic, subtopic: subtopic }} ->
            value = <<
              req_id :: unsigned-big-integer-unit(1)-size(16),
              topic :: unsigned-big-integer-unit(1)-size(8),
              subtopic :: unsigned-big-integer-unit(1)-size(8)
            >>
            _ = rpc_send_rep(data, read, value)
            :keep_state_and_data
          {:ok, %Sub{ active: false }} ->
            _ = rpc_send_rep(data, read, <<>>)
            :keep_state_and_data
        end
      @topic_pubsub_subtopic_count ->
        {value, _, _} = rpc_sub_free(data)
        value = @rpc_sub_max - value
        _ = rpc_send_rep(data, read, << value >>)
        :keep_state_and_data
      @topic_pubsub_subtopic_free ->
        {value, _, _} = rpc_sub_free(data)
        _ = rpc_send_rep(data, read, << value >>)
        :keep_state_and_data
      @topic_pubsub_subtopic_max ->
        value = @rpc_sub_max
        _ = rpc_send_rep(data, read, << value >>)
        :keep_state_and_data
      @topic_pubsub_subtopic_list ->
        payload =
          for {index, %Sub{ active: true, req_id: req_id, topic: topic, subtopic: subtopic }} <- data.subs, into: <<>> do
            <<
              index,
              req_id :: unsigned-big-integer-unit(1)-size(16),
              topic :: unsigned-big-integer-unit(1)-size(8),
              subtopic :: unsigned-big-integer-unit(1)-size(8)
            >>
          end
        :ok = rpc_send_rep(data, read, payload)
        :keep_state_and_data
      @topic_pubsub_subtopic_all ->
        flag = 0
        # LIST
        payload =
          for {index, %Sub{ active: true, req_id: req_id, topic: topic, subtopic: subtopic }} <- data.subs, into: <<>> do
            <<
              index,
              req_id :: unsigned-big-integer-unit(1)-size(16),
              topic :: unsigned-big-integer-unit(1)-size(8),
              subtopic :: unsigned-big-integer-unit(1)-size(8)
            >>
          end
        :ok = rpc_send_data(data, read.req_id, read.topic, @topic_pubsub_subtopic_list, flag, payload)
        # COUNT
        {value, _, _} = rpc_sub_free(data)
        value = @rpc_sub_max - value
        :ok = rpc_send_data(data, read.req_id, read.topic, @topic_pubsub_subtopic_count, flag, << value >>)
        # FREE
        {value, _, _} = rpc_sub_free(data)
        :ok = rpc_send_data(data, read.req_id, read.topic, @topic_pubsub_subtopic_free, flag, << value >>)
        # MAX
        value = @rpc_sub_max
        :ok = rpc_send_data(data, read.req_id, read.topic, @topic_pubsub_subtopic_max, flag, << value >>)
        :ok = rpc_send_data(data, read.req_id, read.topic, @topic_pubsub_subtopic_max, flag, << value >>)
        flag = flag ||| @data_flag_end
        :ok = rpc_send_data(data, read.req_id, read.topic, read.subtopic, flag, <<>>)
        :keep_state_and_data
      _ ->
        _ = rpc_send_rep_error(data, read.req_id, read.topic, read.subtopic, @error_bad_subtopic)
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_read_clock(data, read) do
    case read.subtopic do
      @topic_clock_subtopic_now ->
        _ = rpc_send_rep(data, read, << (:os.system_time(:millisecond)) :: unsigned-big-integer-unit(1)-size(64) >>)
        :keep_state_and_data
      _ ->
        _ = rpc_send_rep_error(data, read.req_id, read.topic, read.subtopic, @error_bad_subtopic)
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_read_motor(data, read) do
    case read.subtopic do
      i when i < 10 ->
        value = Map.fetch!(data.motors, i)
        _ = rpc_send_rep(data, read, <<
          value :: signed-big-integer-unit(1)-size(8)
        >>)
        :keep_state_and_data
      @topic_motor_subtopic_all ->
        payload =
          for {index, value} <- data.motors, into: <<>> do
            <<
              index :: signed-big-integer-unit(1)-size(8),
              value :: signed-big-integer-unit(1)-size(8)
            >>
          end
        :ok = rpc_send_rep(data, read, payload)
        :keep_state_and_data
      _ ->
        _ = rpc_send_rep_error(data, read.req_id, read.topic, read.subtopic, @error_bad_subtopic)
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_write(data, write) do
    case write.topic do
      @topic_motor ->
        rpc_recv_write_motor(data, write)
      _ ->
        _ = rpc_send_rep_error(data, write.req_id, write.topic, write.subtopic, @error_bad_subtopic)
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_write_motor(data, write) do
    case write.subtopic do
      i when i < 10 ->
        case write.value do
          << value :: signed-big-integer-unit(1)-size(8) >> ->
            data = %{ data | motors: Map.put(data.motors, i, value) }
            {:keep_state, data}
          _ ->
            :keep_state_and_data
        end
      @topic_motor_subtopic_all ->
        if byte_size(write.value) == 0 or rem(byte_size(write.value), 2) != 0 do
          :keep_state_and_data
        else
          rpc_recv_write_motor_all(data, write.value)
        end
      _ ->
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_recv_write_motor_all(data, << index :: signed-big-integer-unit(1)-size(8), value :: signed-big-integer-unit(1)-size(8), rest :: binary() >>) do
    if index >= 0 and index < 10 do
      data = %{ data | motors: Map.put(data.motors, index, value) }
      rpc_recv_write_motor_all(data, rest)
    else
      rpc_recv_write_motor_all(data, rest)
    end
  end
  defp rpc_recv_write_motor_all(data, <<>>) do
    {:keep_state, data}
  end

  @doc false
  defp rpc_recv_subscribe(data, subscribe) do
    sub = %Sub{
      active: true,
      req_id: subscribe.req_id,
      topic: subscribe.topic,
      subtopic: subscribe.subtopic
    }
    case rpc_sub_find(data, subscribe.req_id) do
      {:ok, _} ->
        :ok = rpc_send_pub_error(data, sub, @error_bad_req_id)
        :keep_state_and_data
      :error ->
        case rpc_sub_free(data) do
          {0, _, _} ->
            :ok = rpc_send_pub_error(data, sub, @error_sub_max)
            :keep_state_and_data
          {_, i, _} ->
            subs = Map.put(data.subs, i, sub)
            data = %{ data | subs: subs }
            {:keep_state, data, [{:state_timeout, @publish, :publish}]}
        end
    end
  end

  @doc false
  defp rpc_recv_unsubscribe(data, unsubscribe) do
    tmp = %Sub{
      active: true,
      req_id: unsubscribe.req_id,
      topic: @topic_all,
      subtopic: @topic_all_subtopic_all
    }
    case rpc_sub_find(data, unsubscribe.req_id) do
      {:ok, {i, sub}} ->
        :ok = rpc_send_data(data, sub.req_id, sub.topic, sub.subtopic, @data_flag_pub ||| @data_flag_end, <<>>)
        subs = Map.put(data.subs, i, %Sub{})
        data = %{ data | subs: subs }
        {:keep_state, data}
      :error ->
        :ok = rpc_send_pub_error(data, tmp, @error_bad_req_id)
        :keep_state_and_data
    end
  end

  @doc false
  defp rpc_send(%Data{}, frame) do
    vex_rpc_send(frame)
  end

  @doc false
  defp rpc_send_data(data, req_id, topic, subtopic, flag, value) do
    data_frame = Vex.Frame.data(req_id, topic, subtopic, flag, @state.next_ticks(), value)
    rpc_send(data, data_frame)
  end

  @doc false
  defp rpc_send_pub(data, %Sub{ req_id: req_id, topic: topic, subtopic: subtopic }, value) do
    flag = @data_flag_pub
    rpc_send_data(data, req_id, topic, subtopic, flag, value)
  end

  @doc false
  defp rpc_send_pub_error(data, %Sub{ req_id: req_id, topic: topic, subtopic: subtopic }, error) do
    flag = @data_flag_pub ||| @data_flag_error ||| @data_flag_end
    rpc_send_data(data, req_id, topic, subtopic, flag, << error >>)
  end

  @doc false
  defp rpc_send_rep(data, %Vex.Frame.READ{ req_id: req_id, topic: topic, subtopic: subtopic }, value) do
    flag = @data_flag_end
    rpc_send_data(data, req_id, topic, subtopic, flag, value)
  end

  @doc false
  defp rpc_send_rep_error(data, req_id, topic, subtopic, error) do
    flag = @data_flag_error ||| @data_flag_end
    rpc_send_data(data, req_id, topic, subtopic, flag, << error >>)
  end

  @doc false
  defp rpc_sub_find(%{ subs: subs }, req_id) do
    rpc_sub_find(Map.to_list(subs), req_id)
  end
  defp rpc_sub_find([sub = {_, %{ active: true, req_id: req_id }} | _], req_id) do
    {:ok, sub}
  end
  defp rpc_sub_find([_ | rest], req_id) do
    rpc_sub_find(rest, req_id)
  end
  defp rpc_sub_find([], _req_id) do
    :error
  end

  @doc false
  defp rpc_sub_free(%Data{ subs: subs }) do
    rpc_sub_free(:lists.usort(:maps.to_list(subs)), 0, nil)
  end

  @doc false
  defp rpc_sub_free([sub = {_, %Sub{ active: false }} | rest], free, nil) do
    rpc_sub_free(rest, free + 1, sub)
  end
  defp rpc_sub_free([{_, %Sub{ active: false }} | rest], free, sub) do
    rpc_sub_free(rest, free + 1, sub)
  end
  defp rpc_sub_free([{_, %Sub{ active: true }} | rest], free, sub) do
    rpc_sub_free(rest, free, sub)
  end
  defp rpc_sub_free([], free, {i, sub}) do
    {free, i, sub}
  end
  defp rpc_sub_free([], free, nil) do
    {free, nil, nil}
  end

end