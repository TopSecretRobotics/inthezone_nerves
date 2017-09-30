defmodule UiGraph.Relay.Node.ParseIDs.Rule do
  alias UiGraph.Relay.Node.ParseIDs

  @enforce_keys [:key]
  defstruct [
    :key,
    expected_types: [],
    output_mode: :full,
    schema: nil,
  ]

  @type t :: %__MODULE__{
    key: atom,
    expected_types: [atom],
    output_mode: :full | :simple,
  }

  @spec output(t, ParseIDs.result) :: ParseIDs.full_result | ParseIDs.simple_result
  def output(%{output_mode: :full}, result), do: result
  def output(%{output_mode: :simple}, %{id: id}), do: id

end
