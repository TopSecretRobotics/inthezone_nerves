defmodule Ui.Events.Ping do

  @type t() :: %__MODULE__{
    id: integer(),
    source: module(),
    direction: :in | :out,
    seq_id: integer()
  }

  defstruct [
    id: nil,
    source: nil,
    direction: nil,
    seq_id: nil
  ]

end
