defmodule Ui.Events.Frame do

  @type t() :: %__MODULE__{
    id: integer(),
    source: module(),
    direction: :in | :out,
    frame: binary()
  }

  defstruct [
    id: nil,
    source: nil,
    direction: nil,
    frame: nil
  ]

  def new(id, source, direction, frame) do
    case frame do
      %Vex.Frame.PING{ seq_id: seq_id } ->
        %Ui.Events.Ping{
          id: id,
          source: source,
          direction: direction,
          seq_id: seq_id
        }
      %Vex.Frame.PONG{ seq_id: seq_id } ->
        %Ui.Events.Pong{
          id: id,
          source: source,
          direction: direction,
          seq_id: seq_id
        }
      %Vex.Frame.INFO{ topic: topic, subtopic: subtopic, value: value } ->
        %Ui.Events.Info{
          id: id,
          source: source,
          direction: direction,
          topic: topic,
          subtopic: subtopic,
          value: :erlang.iolist_to_binary(:io_lib.format('~w', [value]))
        }
      %Vex.Frame.DATA{ req_id: req_id, topic: topic, subtopic: subtopic, flag: flag, ticks: ticks, value: value } ->
        %Ui.Events.Data{
          id: id,
          source: source,
          direction: direction,
          req_id: req_id,
          topic: topic,
          subtopic: subtopic,
          flag: Map.take(flag, [:end, :pub, :error]),
          ticks: ticks,
          value: :erlang.iolist_to_binary(:io_lib.format('~w', [value]))
        }
      %Vex.Frame.READ{ req_id: req_id, topic: topic, subtopic: subtopic } ->
        %Ui.Events.Read{
          id: id,
          source: source,
          direction: direction,
          req_id: req_id,
          topic: topic,
          subtopic: subtopic
        }
      %Vex.Frame.WRITE{ req_id: req_id, topic: topic, subtopic: subtopic, value: value } ->
        %Ui.Events.Write{
          id: id,
          source: source,
          direction: direction,
          req_id: req_id,
          topic: topic,
          subtopic: subtopic,
          value: :erlang.iolist_to_binary(:io_lib.format('~w', [value]))
        }
      %Vex.Frame.SUBSCRIBE{ req_id: req_id, topic: topic, subtopic: subtopic } ->
        %Ui.Events.Subscribe{
          id: id,
          source: source,
          direction: direction,
          req_id: req_id,
          topic: topic,
          subtopic: subtopic
        }
      %Vex.Frame.UNSUBSCRIBE{ req_id: req_id } ->
        %Ui.Events.Unsubscribe{
          id: id,
          source: source,
          direction: direction,
          req_id: req_id
        }
      _ when is_binary(frame) ->
        %Ui.Events.Frame{
          id: id,
          source: source,
          direction: direction,
          frame: frame
        }
    end
  end

end
