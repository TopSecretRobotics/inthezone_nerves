defmodule Vex.LinkState do
  use GenServer
  use Bitwise

  def start_link(name) do
    GenServer.start_link(__MODULE__, [], [name: name])
  end

  def next_req_id(pid) do
    GenServer.call(pid, :next_req_id, :infinity)
  end

  def next_ticks(pid) do
    GenServer.call(pid, :next_ticks, :infinity)
  end

  def reset_req_id(pid) do
    GenServer.cast(pid, :reset_req_id)
  end

  def reset_ticks(pid) do
    GenServer.cast(pid, :reset_ticks)
  end

  defmodule Data do
    defstruct [
      req_id: nil,
      timestamp: nil
    ]
  end

  alias __MODULE__.Data, as: Data

  @impl GenServer
  def init([]) do
    data = %Data{
      req_id: 0,
      timestamp: :erlang.monotonic_time(:millisecond)
    }
    {:ok, data}
  end

  @impl GenServer
  def handle_call(:next_req_id, _from, data = %Data{ req_id: req_id }) do
    reply = req_id
    data = %{ data | req_id: (req_id + 1) &&& 0xffff }
    {:reply, reply, data}
  end
  def handle_call(:next_ticks, _from, data = %Data{ timestamp: timestamp }) do
    reply = :erlang.monotonic_time(:millisecond) - timestamp
    {:reply, reply, data}
  end

  @impl GenServer
  def handle_cast(:reset_req_id, data = %Data{}) do
    data = %{ data | req_id: 0 }
    {:noreply, data}
  end
  def handle_cast(:reset_ticks, data = %Data{}) do
    data = %{ data | timestamp: :erlang.monotonic_time(:millisecond) }
    {:noreply, data}
  end
end