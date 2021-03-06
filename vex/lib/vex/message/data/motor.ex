defmodule Vex.Message.Data.Motor do

  @topic_motor_subtopic_all 0xff

  alias Vex.Message.Data

  def decode(%Data{ req_id: req_id, topic: __MODULE__, subtopic: subtopic, flag: flag, ticks: ticks, value: value }) do
    with {:ok, type} <- subtopic_to_type(subtopic) do
      type.decode(req_id, subtopic, flag, ticks, value)
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
      @topic_motor_subtopic_all -> Data.Motor.All
      _ when subtopic in 0..255 -> Data.Motor.Item
    end
  end

  def type_to_subtopic(type) do
    try do
      {:ok, type_to_subtopic!(type)}
    catch _,_ ->
      :error
    end
  end

  def type_to_subtopic!(subtopic) when is_atom(subtopic) or is_integer(subtopic) do
    case subtopic do
      Data.Motor.All -> @topic_motor_subtopic_all
      _ when subtopic in 0..255 -> subtopic
    end
  end

end
