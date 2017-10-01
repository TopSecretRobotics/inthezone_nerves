defmodule Vex.Message.Data.Cassette do

  @topic_cassette_subtopic_open 0xfa
  @topic_cassette_subtopic_count 0xfb
  @topic_cassette_subtopic_free 0xfc
  @topic_cassette_subtopic_max 0xfd
  # @topic_cassette_subtopic_list 0xfe
  # @topic_cassette_subtopic_all 0xff

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
      @topic_cassette_subtopic_open -> Data.Cassette.Open
      @topic_cassette_subtopic_count -> Data.Cassette.Count
      @topic_cassette_subtopic_free -> Data.Cassette.Free
      @topic_cassette_subtopic_max -> Data.Cassette.Max
      # @topic_cassette_subtopic_list -> Data.Cassette.List
      # @topic_cassette_subtopic_all -> Data.Cassette.All
      _ when subtopic in 0..255 -> Data.Cassette.Item
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
      Data.Cassette.Open -> @topic_cassette_subtopic_open
      Data.Cassette.Count -> @topic_cassette_subtopic_count
      Data.Cassette.Free -> @topic_cassette_subtopic_free
      Data.Cassette.Max -> @topic_cassette_subtopic_max
      # Data.Cassette.List -> @topic_cassette_subtopic_list
      # Data.Cassette.All -> @topic_cassette_subtopic_all
      _ when subtopic in 0..255 -> subtopic
    end
  end

end
