defmodule Vex.Message.Write.Cassette do

  @topic_cassette_subtopic_write 0xf8
  @topic_cassette_subtopic_close 0xf9
  @topic_cassette_subtopic_open 0xfa

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
      _ when subtopic in [@topic_cassette_subtopic_write, :write] -> Write.Cassette.Write
      _ when subtopic in [@topic_cassette_subtopic_close, :close] -> Write.Cassette.Close
      _ when subtopic in [@topic_cassette_subtopic_open, :open] -> Write.Cassette.Open
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
      Write.Cassette.Write -> @topic_cassette_subtopic_write
      Write.Cassette.Close -> @topic_cassette_subtopic_close
      Write.Cassette.Open -> @topic_cassette_subtopic_open
    end
  end

end
