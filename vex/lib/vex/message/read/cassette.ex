defmodule Vex.Message.Read.Cassette do

  @topic_cassette_subtopic_open 0xfa
  @topic_cassette_subtopic_count 0xfb
  @topic_cassette_subtopic_free 0xfc
  @topic_cassette_subtopic_max 0xfd
  # @topic_cassette_subtopic_list 0xfe
  # @topic_cassette_subtopic_all 0xff

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
      _ when subtopic in [@topic_cassette_subtopic_open, :open] -> Read.Cassette.Open
      _ when subtopic in [@topic_cassette_subtopic_count, :count] -> Read.Cassette.Count
      _ when subtopic in [@topic_cassette_subtopic_free, :free] -> Read.Cassette.Free
      _ when subtopic in [@topic_cassette_subtopic_max, :max] -> Read.Cassette.Max
      # _ when subtopic in [@topic_cassette_subtopic_list, :list] -> Read.Cassette.List
      # _ when subtopic in [@topic_cassette_subtopic_all, :all] -> Read.Cassette.All
      _ when subtopic in 0..255 -> Read.Cassette.Item
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
      Read.Cassette.Open -> @topic_cassette_subtopic_open
      Read.Cassette.Count -> @topic_cassette_subtopic_count
      Read.Cassette.Free -> @topic_cassette_subtopic_free
      Read.Cassette.Max -> @topic_cassette_subtopic_max
      # Read.Cassette.List -> @topic_cassette_subtopic_list
      # Read.Cassette.All -> @topic_cassette_subtopic_all
      _ when subtopic in 0..255 -> subtopic
    end
  end

end
