defmodule Vex.Message.Data.Clock do

  @topic_clock_subtopic_now 0x00

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
      @topic_clock_subtopic_now -> Data.Clock.Now
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
      Data.Clock.Now -> @topic_clock_subtopic_now
    end
  end

end
