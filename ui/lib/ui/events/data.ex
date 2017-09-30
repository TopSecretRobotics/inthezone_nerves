defmodule Ui.Events.Data do

  @type t() :: %__MODULE__{
    id: integer(),
    source: module(),
    direction: :in | :out,
    req_id: integer(),
    topic: integer(),
    subtopic: integer(),
    flag: %{
      end: boolean(),
      pub: boolean(),
      error: boolean()
    },
    ticks: integer(),
    value: binary()
  }

  defstruct [
    id: nil,
    source: nil,
    direction: nil,
    req_id: nil,
    topic: nil,
    subtopic: nil,
    flag: nil,
    ticks: nil,
    value: nil
  ]

end
