defmodule Vex.Message.Info.Robot do

  @topic_robot_subtopic_spi 0x00

  alias Vex.Message.Info

  def decode(%Info{ topic: __MODULE__, subtopic: subtopic, value: value }) do
    with {:ok, type} <- subtopic_to_type(subtopic) do
      type.decode(subtopic, value)
    else _ ->
      :error
    end
  end
  def decode(_) do
    :error
  end

  def subtopic_to_type(subtopic) do
    try do
      {:ok, subtopic_to_type!(subtopic)}
    catch _,_ ->
      :error
    end
  end

  def subtopic_to_type!(subtopic) when is_integer(subtopic) do
    case subtopic do
      @topic_robot_subtopic_spi -> Info.Robot.Spi
    end
  end

  def type_to_subtopic(type) do
    try do
      {:ok, type_to_subtopic!(type)}
    catch _,_ ->
      :error
    end
  end

  def type_to_subtopic!(subtopic) when is_atom(subtopic) do
    case subtopic do
      Info.Robot.Spi -> @topic_robot_subtopic_spi
    end
  end

end
