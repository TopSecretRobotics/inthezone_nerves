defmodule Vex.Message.Info.Network.Ipv4 do

  defstruct [
    value: nil
  ]

  def new(ipv4 = {_, _, _, _}) do
    %__MODULE__{
      value: ipv4
    }
  end

  def decode(_subtopic, << a, b, c, d >>) do
    {:ok, new({a, b, c, d})}
  end
  def decode(_, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Info.Network.Ipv4 do
  def encode(%@for{ value: {a, b, c, d} }) do
    info_message = Vex.Message.Info.new(Vex.Message.Info.Network, @for, << a, b, c, d >>)
    Vex.FrameEncoder.encode(info_message)
  end
end
