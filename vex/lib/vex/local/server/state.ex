defmodule Vex.Local.Server.State do

  @state Vex.LinkState

  def start_link() do
    @state.start_link(__MODULE__)
  end

  def next_req_id() do
    @state.next_req_id(__MODULE__)
  end

  def next_ticks() do
    @state.next_ticks(__MODULE__)
  end

  def reset_req_id() do
    @state.reset_req_id(__MODULE__)
  end

  def reset_ticks() do
    @state.reset_ticks(__MODULE__)
  end

end