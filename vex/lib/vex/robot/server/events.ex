defmodule Vex.Robot.Server.Events do

  @events Vex.Event
  @target Vex.Robot.Server

  @frames_event "robot.server.frames"
  @status_event "robot.server.status"

  def connected() do
    @events.broadcast!(@status_event, {@target, :status, :connected})
  end

  def disconnected() do
    @events.broadcast!(@status_event, {@target, :status, :disconnected})
  end

  def frame_in(frame) do
    @events.broadcast!(@frames_event, {@target, :frame, {:in, frame}})
  end

  def frame_out(frame) do
    @events.broadcast!(@frames_event, {@target, :frame, {:out, frame}})
  end

  def list_events() do
    [
      @frames_event,
      @status_event
    ]
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
    @events.subscribe(@frames_event)
  end

  def subscribe_status() do
    @events.subscribe(@status_event)
  end

  def unsubscribe_all() do
    _ = @events.unsubscribe(@frames_event)
    _ = @events.unsubscribe(@status_event)
    :ok
  end

end