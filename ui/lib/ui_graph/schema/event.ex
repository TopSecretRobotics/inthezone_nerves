defmodule UiGraph.Schema.Event do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  use UiGraph.Event.Notation
  alias UiGraph.Schema

  event object :event_status do
    field :connected, non_null(:boolean)
  end

  event object :event_frame do
    field :direction, non_null(:string)
    field :frame, list_of(:integer), resolve: &Schema.Event.export_frame/3
  end

  event object :event_ping do
    field :direction, non_null(:string)
    field :seq_id, non_null(:integer)
  end

  event object :event_pong do
    field :direction, non_null(:string)
    field :seq_id, non_null(:integer)
  end

  event object :event_info do
    field :direction, non_null(:string)
    field :topic, non_null(:integer)
    field :subtopic, non_null(:integer)
    field :value, non_null(:string)
  end

  object :event_data_flag do
    field :end, non_null(:boolean)
    field :pub, non_null(:boolean)
    field :error, non_null(:boolean)
  end

  event object :event_data do
    field :direction, non_null(:string)
    field :req_id, non_null(:integer)
    field :topic, non_null(:integer)
    field :subtopic, non_null(:integer)
    field :flag, non_null(:event_data_flag)
    field :ticks, non_null(:integer)
    field :value, non_null(:string)
  end

  event object :event_read do
    field :direction, non_null(:string)
    field :req_id, non_null(:integer)
    field :topic, non_null(:integer)
    field :subtopic, non_null(:integer)
  end

  event object :event_write do
    field :direction, non_null(:string)
    field :req_id, non_null(:integer)
    field :topic, non_null(:integer)
    field :subtopic, non_null(:integer)
    field :value, non_null(:string)
  end

  event object :event_subscribe do
    field :direction, non_null(:string)
    field :req_id, non_null(:integer)
    field :topic, non_null(:integer)
    field :subtopic, non_null(:integer)
  end

  event object :event_unsubscribe do
    field :direction, non_null(:string)
    field :req_id, non_null(:integer)
  end

  object :event_queries do
    field :local_server_events, type: list_of(:event) do
      arg :exclude, type: list_of(:string)
      resolve fn (_parent, args, _info) ->
        {:ok, events} = Ui.Vex.Debug.head(:local_server)
        events = Schema.Event.server_exclude(events, args[:exclude] || [])
        {:ok, events}
      end
    end

    field :local_socket_events, type: list_of(:event) do
      arg :exclude, type: list_of(:string)
      resolve fn (_parent, args, _info) ->
        {:ok, events} = Ui.Vex.Debug.head(:local_socket)
        events = Schema.Event.socket_exclude(events, args[:exclude] || [])
        {:ok, events}
      end
    end

    field :robot_server_events, type: list_of(:event) do
      arg :exclude, type: list_of(:string)
      resolve fn (_parent, args, _info) ->
        {:ok, events} = Ui.Vex.Debug.head(:robot_server)
        events = Schema.Event.server_exclude(events, args[:exclude] || [])
        {:ok, events}
      end
    end

    field :robot_socket_events, type: list_of(:event) do
      arg :exclude, type: list_of(:string)
      resolve fn (_parent, args, _info) ->
        {:ok, events} = Ui.Vex.Debug.head(:robot_socket)
        events = Schema.Event.socket_exclude(events, args[:exclude] || [])
        {:ok, events}
      end
    end
  end

  object :event_subscriptions do
    field :observe_local_server_events, type: list_of(:event) do
      arg :exclude, type: list_of(:string)
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
      resolve fn (events, args, _info) ->
        events = Schema.Event.server_exclude(events, args[:exclude] || [])
        {:ok, events}
      end
    end

    field :observe_local_socket_events, type: list_of(:event) do
      arg :exclude, type: list_of(:string)
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
      resolve fn (events, args, _info) ->
        events = Schema.Event.socket_exclude(events, args[:exclude] || [])
        {:ok, events}
      end
    end

    field :observe_robot_server_events, type: list_of(:event) do
      arg :exclude, type: list_of(:string)
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
      resolve fn (events, args, _info) ->
        events = Schema.Event.server_exclude(events, args[:exclude] || [])
        {:ok, events}
      end
    end

    field :observe_robot_socket_events, type: list_of(:event) do
      arg :exclude, type: list_of(:string)
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
      resolve fn (events, args, _info) ->
        # require IEx
        # IEx.pry()
        events = Schema.Event.socket_exclude(events, args[:exclude] || [])
        {:ok, events}
      end
    end
  end

  def server_exclude(events, ["PUB" | rest]) do
    events = server_exclude_data_pub(events, [])
    server_exclude(events, rest)
  end
  def server_exclude(events, [type | rest]) do
    type =
      case type do
        "PING" -> Ui.Events.Ping
        "PONG" -> Ui.Events.Pong
        "INFO" -> Ui.Events.Info
        "DATA" -> Ui.Events.Data
        "READ" -> Ui.Events.Read
        "WRITE" -> Ui.Events.Write
        "SUBSCRIBE" -> Ui.Events.Subscribe
        "UNSUBSCRIBE" -> Ui.Events.Unsubscribe
        _ -> nil
      end
    if is_nil(type) do
      server_exclude(events, rest)
    else
      events = server_exclude_type(events, type, [])
      server_exclude(events, rest)
    end
  end
  def server_exclude(events, []) do
    events = server_exclude_type(events, Ui.Events.Frame, [])
    limit_events(events, 0, 100, [])
  end

  def export_frame(%{ frame: frame }, _args, _info) when is_binary(frame) do
    # value = :erlang.iolist_to_binary(:io_lib.format('~w', [frame]))
    value = :binary.bin_to_list(frame)
    {:ok, value}
  end

  def socket_exclude(events, ["IN" | rest]) do
    events = socket_exclude_frame_in(events, [])
    socket_exclude(events, rest)
  end
  def socket_exclude(events, ["OUT" | rest]) do
    events = socket_exclude_frame_out(events, [])
    socket_exclude(events, rest)
  end
  def socket_exclude(events, ["SMALL" | rest]) do
    events = socket_exclude_frame_small(events, [])
    socket_exclude(events, rest)
  end
  def socket_exclude(events, [_ | rest]) do
    socket_exclude(events, rest)
  end
  def socket_exclude(events, []) do
    limit_events(events, 0, 100, [])
  end

  @doc false
  defp socket_exclude_frame_in([event | events], acc) do
    case event do
      %Ui.Events.Frame{ direction: :in } ->
        socket_exclude_frame_in(events, acc)
      _ ->
        socket_exclude_frame_in(events, [event | acc])
    end
  end
  defp socket_exclude_frame_in([], acc) do
    :lists.reverse(acc)
  end

  @doc false
  defp socket_exclude_frame_out([event | events], acc) do
    case event do
      %Ui.Events.Frame{ direction: :out } ->
        socket_exclude_frame_out(events, acc)
      _ ->
        socket_exclude_frame_out(events, [event | acc])
    end
  end
  defp socket_exclude_frame_out([], acc) do
    :lists.reverse(acc)
  end

  @doc false
  defp socket_exclude_frame_small([event | events], acc) do
    case event do
      %Ui.Events.Frame{ frame: value } ->
        exclude =
          case value do
            <<>> -> true
            << 0 >> -> true
            _ -> false
          end
        if exclude do
          socket_exclude_frame_small(events, acc)
        else
          socket_exclude_frame_small(events, [event | acc])
        end
      _ ->
        socket_exclude_frame_small(events, [event | acc])
    end
  end
  defp socket_exclude_frame_small([], acc) do
    :lists.reverse(acc)
  end

  @doc false
  defp server_exclude_data_pub([event | events], acc) do
    case event do
      %Ui.Events.Data{ flag: %{ pub: true } } ->
        server_exclude_data_pub(events, acc)
      _ ->
        server_exclude_data_pub(events, [event | acc])
    end
  end
  defp server_exclude_data_pub([], acc) do
    :lists.reverse(acc)
  end

  @doc false
  defp server_exclude_type([event | events], type, acc) do
    case event do
      %{ __struct__: ^type } ->
        server_exclude_type(events, type, acc)
      _ ->
        server_exclude_type(events, type, [event | acc])
    end
  end
  defp server_exclude_type([], _type, acc) do
    :lists.reverse(acc)
  end

  @doc false
  defp limit_events(events, 0, max, []) when length(events) <= max do
    events
  end
  defp limit_events([_ | events], 0, max, []) do
    limit_events(events, 0, max, [])
  end

  # @doc false
  # defp limit_events(_events, max, max, acc) do
  #   :lists.reverse(acc)
  # end
  # defp limit_events([event | events], n, max, acc) do
  #   limit_events(events, n + 1, max, [event | acc])
  # end
  # defp limit_events([], _n, _max, acc) do
  #   :lists.reverse(acc)
  # end

end
