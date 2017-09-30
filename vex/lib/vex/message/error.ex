defmodule Vex.Message.Error do

  @error_bad_req_id 0x01
  @error_bad_topic 0x02
  @error_bad_subtopic 0x03
  @error_sub_max 0x04

  alias __MODULE__, as: Error

  def decode(%Vex.Frame.DATA{ req_id: req_id, topic: topic, subtopic: subtopic, flag: flag = %{ error: true }, ticks: ticks, value: << value >> }) do
    with {:ok, type} <- value_to_type(value) do
      case Vex.Message.Data.topic_to_type(topic) do
        {:ok, topic_type} ->
          case topic_type.subtopic_to_type(subtopic) do
            {:ok, subtopic_type} ->
              if Map.has_key?(subtopic_type.__struct__(), :index) do
                type.decode(req_id, topic_type, subtopic, flag, ticks)
              else
                type.decode(req_id, topic_type, subtopic_type, flag, ticks)
              end
            :error ->
              type.decode(req_id, topic_type, subtopic, flag, ticks)
          end
        :error ->
          type.decode(req_id, topic, subtopic, flag, ticks)
      end
    end
  end
  def decode(binary) when is_binary(binary) do
    with {:ok, frame} <- Vex.Frame.decode(binary) do
      decode(frame)
    else _ ->
      :error
    end
  end
  def decode(_) do
    :error
  end

  def value_to_type(value) do
    try do
      {:ok, value_to_type!(value)}
    catch _,_ ->
      :error
    end
  end

  def value_to_type!(value) when is_integer(value) do
    case value do
      @error_bad_req_id -> Error.BadReqId
      @error_bad_topic -> Error.BadTopic
      @error_bad_subtopic -> Error.BadSubtopic
      @error_sub_max -> Error.SubMax
    end
  end

  def type_to_value(type) do
    try do
      {:ok, type_to_value!(type)}
    catch _,_ ->
      :error
    end
  end

  def type_to_value!(type) when is_atom(type) do
    case type do
      Error.BadReqId -> @error_bad_req_id
      Error.BadTopic -> @error_bad_topic
      Error.BadSubtopic -> @error_bad_subtopic
      Error.SubMax -> @error_sub_max
    end
  end

end
