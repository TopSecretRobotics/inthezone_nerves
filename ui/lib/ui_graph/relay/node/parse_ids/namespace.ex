defmodule UiGraph.Relay.Node.ParseIDs.Namespace do

  alias UiGraph.Relay.Node.ParseIDs.Config

  @enforce_keys [:key]
  defstruct [
    :key,
    children: [],
  ]

  @type t :: %__MODULE__{
    key: atom,
    children: [Config.node_t],
  }

end
