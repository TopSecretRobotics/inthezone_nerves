defmodule Ui.Events.Subscribe do

  @type t() :: %__MODULE__{
    id: integer(),
    source: module(),
    direction: :in | :out,
    req_id: integer(),
    topic: integer(),
    subtopic: integer()
  }

  defstruct [
    id: nil,
    source: nil,
    direction: nil,
    req_id: nil,
    topic: nil,
    subtopic: nil
  ]

end
