defmodule Vex.Server do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]
  use Bitwise
  require Logger

  def start_link() do
    GenStateMachine.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def read(read = %Vex.Message.READ{}, timeout) do
    GenStateMachine.call(__MODULE__, {:read, read}, timeout)
  end

  def next_req_id() do
    GenStateMachine.call(__MODULE__, :next_req_id, :infinity)
  end

  def connected() do
    GenStateMachine.cast(__MODULE__, :connected)
  end

  def disconnected() do
    GenStateMachine.cast(__MODULE__, :disconnected)
  end

  def handle_message(packet) do
    GenStateMachine.cast(__MODULE__, {:handle_message, packet})
  end

  def send_message(message) do
    with {:ok, frame} <- Vex.Message.encode(message),
         true <- Code.ensure_loaded?(Firmware.Serial),
         true <- function_exported?(Firmware.Serial, :write, 1) do
      Logger.info("VEX send: #{inspect message}")
      :erlang.apply(Firmware.Serial, :write, [frame])
    else _ ->
      :error
    end
  end

  defmodule Data do
    defstruct [
      reads: %{},
      req_id: 0
    ]
  end

  alias __MODULE__.Data, as: Data

  def init([]) do
    data = %Data{}
    if Code.ensure_loaded?(Firmware.Serial) and function_exported?(Firmware.Serial, :connected?, 0) do
      ref = :erlang.make_ref()
      parent = :erlang.self()
      child = :erlang.spawn(fn () ->
        try do
          result = :erlang.apply(Firmware.Serial, :connected?, [])
          _ = :erlang.send(parent, {ref, result})
          :erlang.exit(:normal)
        catch _,_ ->
          :erlang.exit(:normal)
        end
      end)
      receive do
        {^ref, true} ->
          {:ok, :connected, data}
        {^ref, false} ->
          {:ok, :disconnected}
      after
        100 ->
          _ = :erlang.exit(child, :kill)
          {:ok, :disconnected, data}
      end
    else
      {:ok, :disconnected, data}
    end
  end

  # Enter Events
  def handle_event(:enter, old_state, :connected, data) do
    if old_state == :disconnected do
      Logger.info("VEX connected")
    end
    {:keep_state, flush_reads(%{ data | req_id: 0 })}
  end
  def handle_event(:enter, old_state, :disconnected, data) do
    if old_state == :connected do
      Logger.info("VEX disconnected")
    end
    {:keep_state, flush_reads(%{ data | req_id: 0 })}
  end
  # Call Events
  def handle_event({:call, from}, :next_req_id, :connected, data = %Data{ req_id: req_id }) do
    reply = {:ok, req_id}
    data = %{ data | req_id: (req_id + 1) &&& 0xffff }
    {:keep_state, data, [{:reply, from, reply}]}
  end
  def handle_event({:call, from}, {:read, read = %Vex.Message.READ{ req_id: req_id }}, :connected, data = %Data{ reads: reads }) do
    with false <- Map.has_key?(reads, read),
         :ok <- send_message(read) do
      data = %{ data | reads: Map.put(reads, req_id, from) }
      {:keep_state, data}
    else _ ->
      {:keep_state_and_data, [{:reply, from, :error}]}
    end
  end
  def handle_event({:call, from}, _request, :disconnected, _data) do
    {:keep_state_and_data, [{:reply, from, :error}]}
  end
  # Cast Events
  def handle_event(:cast, :connected, state, data) do
    if state == :disconnected do
      {:next_state, :connected, data}
    else
      :keep_state_and_data
    end
  end
  def handle_event(:cast, :disconnected, state, data) do
    if state == :connected do
      {:next_state, :disconnected, data}
    else
      :keep_state_and_data
    end
  end
  def handle_event(:cast, {:handle_message, _}, :disconnected, data) do
    {:next_state, :connected, data, [:postpone]}
  end
  def handle_event(:cast, {:handle_message, message}, :connected, data = %{ reads: reads }) do
    Logger.info("VEX recv: #{inspect message}")
    case message do
      %Vex.Message.DATA{ req_id: req_id } ->
        case Map.fetch(reads, req_id) do
          {:ok, from} ->
            data = %{ data | reads: Map.delete(reads, req_id) }
            {:keep_state, data, [{:reply, from, {:ok, message}}]}
          :error ->
            :keep_state_and_data
        end
      _ ->
        :keep_state_and_data
    end
  end

  @doc false
  defp flush_reads(data = %Data{ reads: reads }) do
    replies =
      for from <- Map.values(reads), into: [] do
        {:reply, from, :error}
      end
    _ = GenStateMachine.reply(replies)
    %{ data | reads: %{} }
  end

  # @doc false
  # defp parse(packet) do
  #   case packet do
  #   case packet do
  #     << @pin, seq_id >> ->
  #     << @pon, seq_id >> ->
  #     << @dat, len, value :: binary-size(len) >> ->
  #     << @get, req_id, type, topic >> ->
  #     << @rep, req_id, len, value :: binary-size(len) >> ->
  #     << @set, req_id, type, topic, len, value :: binary-size(len) >> ->
  #     << @sub, req_id, type, topic >> ->
  #     << @uns, req_id >> ->
  #     << @pub, req_id, type, topic, len, value :: binary-size(len) >> ->
  #   end
  # end

end