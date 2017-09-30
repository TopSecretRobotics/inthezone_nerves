defmodule UiGraph.Relay.Schema.Notation do
  @moduledoc """
  Used to extend a module where Absinthe types are defined with
  Relay-specific macros and types.

  See `UiGraph.Relay`.
  """

  defmacro __using__(_opts) do
    quote do
      import UiGraph.Relay.Mutation.Notation, only: :macros
      import UiGraph.Relay.Node.Notation, only: :macros
      import UiGraph.Relay.Node.Helpers
      import UiGraph.Relay.Connection.Notation, only: :macros
    end
  end

end
