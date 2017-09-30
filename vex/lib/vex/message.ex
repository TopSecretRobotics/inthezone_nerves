defmodule Vex.Message do
  use Vex.Stdint

  alias __MODULE__.{
    Info,
    Data,
    Read,
    Write,
    Subscribe
  }

  alias Vex.Frame.{
    INFO,
    DATA,
    READ,
    WRITE,
    SUBSCRIBE
  }

  ## Encode/Decode

  def decode(frame = %INFO{}) do
    Info.decode(frame)
  end
  def decode(frame = %DATA{}) do
    Data.decode(frame)
  end
  def decode(frame = %READ{}) do
    Read.decode(frame)
  end
  def decode(frame = %WRITE{}) do
    Write.decode(frame)
  end
  def decode(frame = %SUBSCRIBE{}) do
    Subscribe.decode(frame)
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

  defdelegate encode(frame), to: Vex.Frame

end
