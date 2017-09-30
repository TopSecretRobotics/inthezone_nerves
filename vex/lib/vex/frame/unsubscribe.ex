defmodule Vex.Frame.UNSUBSCRIBE do

  @type t() :: %__MODULE__{
    req_id: Vex.Stdint.uint16_t()
  }

  defstruct [
    req_id: nil
  ]

  def new(req_id) do
    Vex.Frame.unsubscribe(req_id)
  end

  def decode(<<
    req_id :: unsigned-big-integer-unit(1)-size(16)
  >>) do
    {:ok, new(req_id)}
  end
  def decode(_) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Frame.UNSUBSCRIBE do
  def encode(%@for{ req_id: req_id }) do
    op = Vex.Frame.type_to_op!(@for)
    <<
      op,
      req_id :: unsigned-big-integer-unit(1)-size(16)
    >>
  end
end

defimpl OJSON.Encoder, for: Vex.Frame.UNSUBSCRIBE do
  def encode(%@for{ req_id: req_id }, options) do
    op = Vex.Frame.type_to_op!(@for)
    map = %{
      op: op,
      req_id: req_id
    }
    OJSON.Encoder.encode(["UNSUBSCRIBE", map], options)
  end
end
