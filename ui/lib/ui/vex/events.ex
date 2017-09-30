defmodule Ui.Vex.Events do

  @events Ui.Vex.Event

  def status_connected() do
    @events.broadcast!("status", {:vex, :status, :connected})
  end

  def status_disconnected() do
    @events.broadcast!("status", {:vex, :status, :disconnected})
  end

  def frame_data(data) do
    @events.broadcast!("frames", {:vex, :data, data})
  end

  def frame_error(data) do
    @events.broadcast!("frames", {:vex, :error, data})
  end

  def frame_end() do
    @events.broadcast!("frames", {:vex, :end})
  end

  def subscribe_all() do
    with :ok <- subscribe_status(),
         :ok <- subscribe_frames() do
      :ok
    else error ->
      :ok = unsubscribe_all()
      error
    end
  end

  def subscribe_frames() do
    @events.subscribe("frames")
  end

  def subscribe_status() do
    @events.subscribe("status")
  end

  def unsubscribe_all() do
    _ = @events.unsubscribe("frames")
    _ = @events.unsubscribe("status")
    :ok
  end

end