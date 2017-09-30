defmodule Ui.Work.Head do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  defmodule State do
    defstruct [
      demand: 0,
      events: []
    ]
  end

  alias __MODULE__.State, as: State

  @impl GenStage
  def init([]) do
    :ok = Ui.Vex.Events.subscribe_frames()
    state = %State{
      events: []
    }
    {:producer, state}
  end

  @impl GenStage
  def handle_demand(demand, state = %State{ demand: old_demand, events: events }) do
    state = %{ state | demand: 0 }
    maybe_emit(demand + old_demand, state)
  end

  @impl GenStage
  def handle_info({:vex, :data, data}, state = %State{ demand: demand, events: events }) do
    events = [data | events]
    state = %{ state | demand: 0, events: events }
    maybe_emit(demand, state)
  end

  @doc false
  def maybe_emit(demand, state = %State{ demand: 0, events: events }) do
    case length(events) do
      n when n <= demand ->
        diff = demand - n
        send_events = :lists.reverse(events)
        state = %{ state | demand: diff, events: [] }
        {:noreply, send_events, state}
      n when n > demand ->
        {:ok, send_events, keep_events} = split_events(events, 0, n - demand, [])
        state = %{ state | demand: 0, events: keep_events }
        {:noreply, send_events, state}
    end
  end

  @doc false
  defp split_events(events, max, max, acc) do
    {:ok, :lists.reverse(events), :lists.reverse(acc)}
  end
  defp split_events([event | events], n, max, acc) do
    split_events(events, n + 1, max, [event | acc])
  end

end