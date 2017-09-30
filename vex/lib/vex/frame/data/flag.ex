defmodule Vex.Frame.DATA.FLAG do
  use Vex.Stdint
  use Bitwise

  @data_flag_end 0x01
  @data_flag_pub 0x02
  @data_flag_error 0x04

  defstruct [
    end: false,
    pub: false,
    error: false
  ]

  def new(flag) when is_uint8_t(flag) do
    %__MODULE__{
      end: (flag &&& @data_flag_end) != 0,
      pub: (flag &&& @data_flag_pub) != 0,
      error: (flag &&& @data_flag_error) != 0
    }
  end
  def new(flag) when is_map(flag) do
    %__MODULE__{
      end: !!Map.get(flag, :end, false),
      pub: !!Map.get(flag, :pub, false),
      error: !!Map.get(flag, :error, false)
    }
  end
  def new(flag) when is_list(flag) do
    new(for key when key in [:end, :pub, :error] <- flag, into: %{}, do: {key, true})
  end

  def to_uint8_t(%__MODULE__{ end: end_flag, pub: pub_flag, error: error_flag }) do
    (if end_flag, do: @data_flag_end, else: 0) ||| (if pub_flag, do: @data_flag_pub, else: 0) ||| (if error_flag, do: @data_flag_error, else: 0)
  end

end

defimpl Vex.FrameEncoder, for: Vex.Frame.DATA.FLAG do
  def encode(flag = %@for{}) do
    <<
      @for.to_uint8_t(flag)
    >>
  end
end

defimpl OJSON.Encoder, for: Vex.Frame.DATA.FLAG do
  def encode(%@for{ end: end_flag, pub: pub_flag, error: error_flag }, options) do
    map = %{
      end: end_flag,
      pub: pub_flag,
      error: error_flag
    }
    OJSON.Encoder.encode(map, options)
  end
end
