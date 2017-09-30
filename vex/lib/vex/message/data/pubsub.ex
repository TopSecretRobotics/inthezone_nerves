defmodule Vex.Message.Data.Pubsub do

  @topic_pubsub_subtopic_count 0xfb
  @topic_pubsub_subtopic_free 0xfc
  @topic_pubsub_subtopic_max 0xfd
  @topic_pubsub_subtopic_list 0xfe
  @topic_pubsub_subtopic_all 0xff

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
      @topic_pubsub_subtopic_count -> Data.Pubsub.Count
      @topic_pubsub_subtopic_free -> Data.Pubsub.Free
      @topic_pubsub_subtopic_max -> Data.Pubsub.Max
      @topic_pubsub_subtopic_list -> Data.Pubsub.List
      @topic_pubsub_subtopic_all -> Data.Pubsub.All
      _ when subtopic in 0..255 -> Data.Pubsub.Item
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
      Data.Pubsub.Count -> @topic_pubsub_subtopic_count
      Data.Pubsub.Free -> @topic_pubsub_subtopic_free
      Data.Pubsub.Max -> @topic_pubsub_subtopic_max
      Data.Pubsub.List -> @topic_pubsub_subtopic_list
      Data.Pubsub.All -> @topic_pubsub_subtopic_all
      _ when subtopic in 0..255 -> subtopic
    end
  end

end
