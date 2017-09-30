defmodule Ui.Events.Status do

  @type t() :: %__MODULE__{
    id: integer(),
    source: module(),
    connected: boolean()
  }

  defstruct [
    id: nil,
    source: nil,
    connected: nil
  ]

end
