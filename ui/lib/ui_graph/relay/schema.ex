defmodule UiGraph.Relay.Schema do
  @moduledoc """
  Used to extend a schema with Relay-specific macros and types.

  See `UiGraph.Relay`.
  """

  defmacro __using__(_opts) do
    quote do
      use UiGraph.Relay.Schema.Notation
      import_types UiGraph.Relay.Connection.Types
    end
  end

end
