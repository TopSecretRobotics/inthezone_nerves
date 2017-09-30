defmodule Ui.Events.Write do

  @type t() :: %__MODULE__{
    id: integer(),
    source: module(),
    direction: :in | :out,
    req_id: integer(),
    topic: integer(),
    subtopic: integer(),
    value: binary()
  }

  defstruct [
    id: nil,
    source: nil,
    direction: nil,
    req_id: nil,
    topic: nil,
    subtopic: nil,
    value: nil
  ]

end
