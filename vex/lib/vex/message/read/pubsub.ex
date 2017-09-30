defmodule Vex.Message.Read.Pubsub do

  @topic_pubsub_subtopic_count 0xfb
  @topic_pubsub_subtopic_free 0xfc
  @topic_pubsub_subtopic_max 0xfd
  @topic_pubsub_subtopic_list 0xfe
  @topic_pubsub_subtopic_all 0xff

  alias Vex.Message.Read

  def cast(req_id, subtopic) do
    with {:ok, type} <- subtopic_to_type(subtopic) do
      type.cast(req_id, subtopic)
    end
  end

  def decode(%Read{ req_id: req_id, topic: __MODULE__, subtopic: subtopic }) do
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
      _ when subtopic in [@topic_pubsub_subtopic_count, :count] -> Read.Pubsub.Count
      _ when subtopic in [@topic_pubsub_subtopic_free, :free] -> Read.Pubsub.Free
      _ when subtopic in [@topic_pubsub_subtopic_max, :max] -> Read.Pubsub.Max
      _ when subtopic in [@topic_pubsub_subtopic_list, :list] -> Read.Pubsub.List
      _ when subtopic in [@topic_pubsub_subtopic_all, :all] -> Read.Pubsub.All
      _ when subtopic in 0..255 -> Read.Pubsub.Item
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
      Read.Pubsub.Count -> @topic_pubsub_subtopic_count
      Read.Pubsub.Free -> @topic_pubsub_subtopic_free
      Read.Pubsub.Max -> @topic_pubsub_subtopic_max
      Read.Pubsub.List -> @topic_pubsub_subtopic_list
      Read.Pubsub.All -> @topic_pubsub_subtopic_all
      _ when subtopic in 0..255 -> subtopic
    end
  end

end
