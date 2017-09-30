defmodule Ui.Events.Unsubscribe do

  @type t() :: %__MODULE__{
    id: integer(),
    source: module(),
    direction: :in | :out,
    req_id: integer()
  }

  defstruct [
    id: nil,
    source: nil,
    direction: nil,
    req_id: nil
  ]

end
