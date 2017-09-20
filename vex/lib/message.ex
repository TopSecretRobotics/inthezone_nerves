defmodule Vex.Message do

  @op_ping 1
  @op_pong 2
  @op_info 3
  @op_data 4
  @op_read 5
  @op_write 6
  @op_subscribe 7
  @op_unsubscribe 8
  @op_publish 9

  alias __MODULE__.{
    PING,
    PONG,
    INFO,
    DATA,
    READ,
    WRITE,
    SUBSCRIBE,
    UNSUBSCRIBE,
    PUBLISH
  }

  defmacro is_uint8_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= 0 and unquote(n) <= 0xff)
    end
  end

  defmacro is_uint16_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= 0 and unquote(n) <= 0xffff)
    end
  end

  def encode(message) do
    Vex.MessageEncoder.encode(message)
  end

  def decode(encoded) do
    case encoded do
      << @op_ping, seq_id >> ->
        {:ok, ping_frame(seq_id)}
      << @op_pong, seq_id >> ->
        {:ok, pong_frame(seq_id)}
      << @op_info, len, value :: binary-size(len) >> ->
        {:ok, info_frame(value)}
      << @op_data, req_id :: unsigned-big-integer-unit(1)-size(16), flag, len, value :: binary-size(len) >> ->
        {:ok, data_frame(req_id, flag, value)}
      << @op_read, req_id :: unsigned-big-integer-unit(1)-size(16), type, topic >> ->
        {:ok, read_frame(req_id, type, topic)}
      << @op_write, req_id :: unsigned-big-integer-unit(1)-size(16), type, topic, len, value :: binary-size(len) >> ->
        {:ok, write_frame(req_id, type, topic, value)}
      << @op_subscribe, req_id :: unsigned-big-integer-unit(1)-size(16), type, topic >> ->
        {:ok, subscribe_frame(req_id, type, topic)}
      << @op_unsubscribe, req_id :: unsigned-big-integer-unit(1)-size(16) >> ->
        {:ok, unsubscribe_frame(req_id)}
      << @op_publish, req_id :: unsigned-big-integer-unit(1)-size(16), type, topic, len, value :: binary-size(len) >> ->
        {:ok, publish_frame(req_id, type, topic, value)}
      _ ->
        :error
    end
  end

  def ping_frame(seq_id) when is_uint8_t(seq_id) do
    %PING{
      op: @op_ping,
      seq_id: seq_id
    }
  end

  def pong_frame(seq_id) when is_uint8_t(seq_id) do
    %PONG{
      op: @op_pong,
      seq_id: seq_id
    }
  end

  def info_frame(value) when is_binary(value) do
    %INFO{
      op: @op_info,
      len: byte_size(value),
      value: value
    }
  end

  def data_frame(req_id, flag, value) when is_uint16_t(req_id) and is_uint8_t(flag) and is_binary(value) do
    %DATA{
      op: @op_data,
      req_id: req_id,
      flag: flag,
      len: byte_size(value),
      value: value
    }
  end

  def read_frame(req_id, type, topic) when is_uint16_t(req_id) and is_uint8_t(type) and is_uint8_t(topic) do
    %READ{
      op: @op_read,
      req_id: req_id,
      type: type,
      topic: topic
    }
  end

  def write_frame(req_id, type, topic, value) when is_uint16_t(req_id) and is_uint8_t(type) and is_uint8_t(topic) and is_binary(value) do
    %WRITE{
      op: @op_write,
      req_id: req_id,
      type: type,
      topic: topic,
      len: byte_size(value),
      value: value
    }
  end

  def subscribe_frame(req_id, type, topic) when is_uint16_t(req_id) and is_uint8_t(type) and is_uint8_t(topic) do
    %SUBSCRIBE{
      op: @op_subscribe,
      req_id: req_id,
      type: type,
      topic: topic
    }
  end

  def unsubscribe_frame(req_id) when is_uint16_t(req_id) do
    %UNSUBSCRIBE{
      op: @op_unsubscribe,
      req_id: req_id
    }
  end

  def publish_frame(req_id, type, topic, value) when is_uint16_t(req_id) and is_uint8_t(type) and is_uint8_t(topic) and is_binary(value) do
    %PUBLISH{
      op: @op_publish,
      req_id: req_id,
      type: type,
      topic: topic,
      len: byte_size(value),
      value: value
    }
  end

end