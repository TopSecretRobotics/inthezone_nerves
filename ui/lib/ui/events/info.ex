defmodule Ui.Events.Info do

  @type t() :: %__MODULE__{
    id: integer(),
    source: module(),
    direction: :in | :out,
    topic: integer(),
    subtopic: integer(),
    value: binary()
  }

  defstruct [
    id: nil,
    source: nil,
    direction: nil,
    topic: nil,
    subtopic: nil,
    value: nil
  ]

end
