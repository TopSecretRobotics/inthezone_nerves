defmodule Vex.Message.Subscribe.All do

  @topic_all_subtopic_all 0xff

  alias Vex.Message.Subscribe

  def cast(req_id, subtopic) do
    with {:ok, type} <- subtopic_to_type(subtopic) do
      type.cast(req_id, subtopic)
    end
  end

  def decode(%Subscribe{ req_id: req_id, topic: __MODULE__, subtopic: subtopic }) do
    with {:ok, type} <- subtopic_to_type(subtopic) do
      type.decode(req_id, subtopic)
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
      _ when subtopic in [@topic_all_subtopic_all, :all] -> Subscribe.All.All
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
      Subscribe.All.All -> @topic_all_subtopic_all
    end
  end

end
