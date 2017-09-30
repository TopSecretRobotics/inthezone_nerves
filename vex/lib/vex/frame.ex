defmodule Vex.Frame do
  use Vex.Stdint

  @op_ping 0x01
  @op_pong 0x02
  @op_info 0x03
  @op_data 0x04
  @op_read 0x05
  @op_write 0x06
  @op_subscribe 0x07
  @op_unsubscribe 0x08

  alias __MODULE__.{
    PING,
    PONG,
    INFO,
    DATA,
    READ,
    WRITE,
    SUBSCRIBE,
    UNSUBSCRIBE
  }

  ## Encode/Decode

  def decode(encoded) do
    with << op, rest :: binary() >> when byte_size(rest) >= 1 <- encoded,
         {:ok, type} <- op_to_type(op) do
      type.decode(rest)
    else _ ->
      :error
    end
  end

  def encode(frame) do
    Vex.FrameEncoder.encode(frame)
  end

  ## Operations

  def op_to_type(op) do
    try do
      {:ok, op_to_type!(op)}
    catch _,_ ->
      :error
    end
  end

  def op_to_type!(op) when is_integer(op) do
    case op do
      @op_ping -> PING
      @op_pong -> PONG
      @op_info -> INFO
      @op_data -> DATA
      @op_read -> READ
      @op_write -> WRITE
      @op_subscribe -> SUBSCRIBE
      @op_unsubscribe -> UNSUBSCRIBE
    end
  end

  def type_to_op(type) do
    try do
      {:ok, type_to_op!(type)}
    catch _,_ ->
      :error
    end
  end

  def type_to_op!(type) when is_atom(type) do
    case type do
      PING -> @op_ping
      PONG -> @op_pong
      INFO -> @op_info
      DATA -> @op_data
      READ -> @op_read
      WRITE -> @op_write
      SUBSCRIBE -> @op_subscribe
      UNSUBSCRIBE -> @op_unsubscribe
    end
  end

  ## Types

  def ping(seq_id) when is_uint8_t(seq_id) do
    %PING{
      seq_id: seq_id
    }
  end

  def pong(seq_id) when is_uint8_t(seq_id) do
    %PONG{
      seq_id: seq_id
    }
  end

  def info(topic, subtopic, value) when is_uint8_t(topic) and is_uint8_t(subtopic) and is_binary(value) do
    %INFO{
      topic: topic,
      subtopic: subtopic,
      value: value
    }
  end

  def data(req_id, topic, subtopic, flag, ticks, value) when is_uint16_t(req_id) and (is_uint8_t(flag) or is_list(flag) or is_map(flag)) and is_uint32_t(ticks) and is_binary(value) do
    %DATA{
      req_id: req_id,
      topic: topic,
      subtopic: subtopic,
      flag: DATA.FLAG.new(flag),
      ticks: ticks,
      value: value
    }
  end

  def read(req_id, topic, subtopic) when is_uint16_t(req_id) and is_uint8_t(topic) and is_uint8_t(subtopic) do
    %READ{
      req_id: req_id,
      topic: topic,
      subtopic: subtopic
    }
  end

  def write(req_id, topic, subtopic, value) when is_uint16_t(req_id) and is_uint8_t(topic) and is_uint8_t(subtopic) and is_binary(value) do
    %WRITE{
      req_id: req_id,
      topic: topic,
      subtopic: subtopic,
      value: value
    }
  end

  def subscribe(req_id, topic, subtopic) when is_uint16_t(req_id) and is_uint8_t(topic) and is_uint8_t(subtopic) do
    %SUBSCRIBE{
      req_id: req_id,
      topic: topic,
      subtopic: subtopic
    }
  end

  def unsubscribe(req_id) when is_uint16_t(req_id) do
    %UNSUBSCRIBE{
      req_id: req_id
    }
  end

end