defmodule Vex.Message.Subscribe.Motor.All do

  defstruct [
    req_id: nil
  ]

  def new(req_id) do
    %__MODULE__{
      req_id: req_id
    }
  end

  def cast(req_id, _subtopic) do
    {:ok, new(req_id)}
  end

  def decode(req_id, subtopic) when is_integer(subtopic) do
    {:ok, new(req_id)}
  end
  def decode(_, _) do
    :error
  end

end

defimpl Vex.FrameEncoder, for: Vex.Message.Subscribe.Motor.All do
  def encode(%@for{ req_id: req_id }) do
    subscribe_message = Vex.Message.Subscribe.new(req_id, Vex.Message.Subscribe.Motor, @for)
    Vex.FrameEncoder.encode(subscribe_message)
  end
end
