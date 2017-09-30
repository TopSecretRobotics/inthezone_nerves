defmodule Ui.Work.Tail do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, [])
  end

  @impl GenStage
  def init([]) do
    {:consumer, nil, [subscribe_to: [Ui.Work.Head]]}
  end

  @impl GenStage
  def handle_events(_events, _from, state) do
    # Process.sleep(1000)
    # require Logger
    # Logger.info("event: #{inspect(hd(:lists.reverse(events)))}")
    {:noreply, [], state}
  end
end
