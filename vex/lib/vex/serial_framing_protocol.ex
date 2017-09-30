defmodule Vex.SerialFramingProtocol do

  def init(_opts) do
    sfp = :serial_framing_protocol_nif.open()
    :ok = :serial_framing_protocol_nif.init(sfp)
    {:disconnected, sfp}
  end

  def connect(sfp, state) do
    :ok = :serial_framing_protocol_nif.init(sfp)
    :ok = :serial_framing_protocol_nif.connect(sfp)
    check_connection(sfp, state)
  end

  def read(sfp, state, iodata) do
    :ok = :serial_framing_protocol_nif.read(sfp, iodata)
    check_connection(sfp, state)
  end

  def write(sfp, state, iodata) do
    :ok = :serial_framing_protocol_nif.write(sfp, iodata)
    check_connection(sfp, state)
  end

  def reset(sfp, _state) do
    :ok = :serial_framing_protocol_nif.init(sfp)
    {:disconnected, sfp}
  end

  @doc false
  defp check_connection(sfp, _state) do
    if :serial_framing_protocol_nif.is_connected(sfp) do
      {:connected, sfp}
    else
      {:disconnected, sfp}
    end
  end

end