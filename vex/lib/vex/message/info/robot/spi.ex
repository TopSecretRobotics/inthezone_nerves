defmodule Vex.Message.Info.Robot.Spi do

  defstruct [
    value: nil
  ]

  def new(value = {_, _, _}) do
    %__MODULE__{
      value: value
    }
  end

  def decode(_subtopic, <<
    ticks :: unsigned-big-integer-unit(1)-size(32),
    main_battery :: unsigned-big-integer-unit(1)-size(16),
    backup_battery :: unsigned-big-integer-unit(1)-size(16)
  >>) do
    {:ok, new({ticks, main_battery, backup_battery})}
  end
  def decode(_, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Info.Robot.Spi do
  def encode(%@for{ value: {ticks, main_battery, backup_battery} }) do
    info_message = Vex.Message.Info.new(Vex.Message.Info.Robot, @for, <<
      ticks :: unsigned-big-integer-unit(1)-size(32),
      main_battery :: unsigned-big-integer-unit(1)-size(16),
      backup_battery :: unsigned-big-integer-unit(1)-size(16)
    >>)
    Vex.FrameEncoder.encode(info_message)
  end
end
