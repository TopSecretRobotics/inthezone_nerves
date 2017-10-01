defmodule Vex.State.Events do

  @events Vex.State.Event
  @target Vex.State

  @cortex_event "cortex"
  @frames_event "frames"
  @motors_event "motors"
  @status_event "status"

  def status_connected() do
    @events.broadcast!(@status_event, {@target, {:status, :connected}})
  end

  def status_disconnected() do
    @events.broadcast!(@status_event, {@target, {:status, :disconnected}})
  end

  def frame_data(data) do
    @events.broadcast!(@frames_event, {@target, {:frame_data, data}})
  end

  def frame_error(data) do
    @events.broadcast!(@frames_event, {@target, {:frame_error, data}})
  end

  def frame_end() do
    @events.broadcast!(@frames_event, {@target, :frame_end})
  end

  def cortex(data) do
    @events.broadcast!(@cortex_event, {@target, {:cortex, data}})
  end

  def motor_state(ticks, value) do
    @events.broadcast!(@motors_event, {@target, {:motor_state, ticks, value}})
  end

  def list_events() do
    [
      @cortex_event,
      @frames_event,
      @motors_event,
      @status_event
    ]
  end

  def subscribe_all() do
    with :ok <- subscribe_status(),
         :ok <- subscribe_frames(),
         :ok <- subscribe_cortex(),
         :ok <- subscribe_motors() do
      :ok
    else error ->
      :ok = unsubscribe_all()
      error
    end
  end

  def subscribe_status() do
    @events.subscribe(Vex.State.Subscriber, @status_event)
  end

  def subscribe_frames() do
    @events.subscribe(Vex.State.Subscriber, @frames_event)
  end

  def subscribe_cortex() do
    @events.subscribe(Vex.State.Cortex, @cortex_event)
  end

  def subscribe_motors() do
    @events.subscribe(Vex.State.Motors, @motors_event)
  end

  def unsubscribe_status() do
    @events.unsubscribe(Vex.State.Subscriber, @status_event)
  end

  def unsubscribe_frames() do
    @events.unsubscribe(Vex.State.Subscriber, @frames_event)
  end

  def unsubscribe_cortex() do
    @events.unsubscribe(Vex.State.Cortex, @cortex_event)
  end

  def unsubscribe_motors() do
    @events.unsubscribe(Vex.State.Motors, @motors_event)
  end

  def unsubscribe_all() do
    _ = unsubscribe_status()
    _ = unsubscribe_frames()
    _ = unsubscribe_cortex()
    _ = unsubscribe_motors()
    :ok
  end

end