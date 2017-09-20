defmodule Vex do
  @timeout 5000

  @type_clock 0
  @type_motor 1

  def read(type, topic, timeout \\ @timeout)
  def read(type, topic, timeout) do
    with {:ok, req_id} <- Vex.Server.next_req_id() do
      read = Vex.Message.read_frame(req_id, type, topic)
      Vex.Server.read(read, timeout)
    end
  end

  def write(type, topic, value) do
    with {:ok, req_id} <- Vex.Server.next_req_id() do
      write = Vex.Message.write_frame(req_id, type, topic, value)
      Vex.Server.send_message(write)
    end
  end

  def motor_get(index, timeout \\ @timeout) do
    with {:ok, %{ value: << value :: unsigned-big-integer-unit(1)-size(16) >>}} <- read(@type_motor, index, timeout) do
      {:ok, value}
    end
  end

  def motor_set(index, value) do
    write(@type_motor, index, << value :: unsigned-big-integer-unit(1)-size(16) >>)
  end

  def time_now(timeout \\ @timeout) do
    with {:ok, %{ value: << value :: unsigned-big-integer-unit(1)-size(32) >>}} <- read(@type_clock, 0, timeout) do
      {:ok, value}
    else _ ->
      :error
    end
  end
end
