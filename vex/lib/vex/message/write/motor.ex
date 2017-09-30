defmodule Vex.Message.Write.Motor do

  @topic_motor_subtopic_all 0xff

  alias Vex.Message.Write

  def cast(req_id, subtopic, value) do
    with {:ok, type} <- subtopic_to_type(subtopic) do
      type.cast(req_id, subtopic, value)
    end
  end

  def decode(%Write{ req_id: req_id, topic: __MODULE__, subtopic: subtopic, value: value }) do
    with {:ok, type} <- subtopic_to_type(subtopic) do
      type.decode(req_id, subtopic, value)
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

  def subtopic_to_type!(subtopic) do
    case subtopic do
      _ when subtopic in [@topic_motor_subtopic_all, :all] -> Write.Motor.All
      _ when subtopic in 0..255 -> Write.Motor.Item
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
      Write.Motor.All -> @topic_motor_subtopic_all
      _ when subtopic in 0..255 -> subtopic
    end
  end

end
