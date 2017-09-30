defmodule UiGraph.Relay do
  @moduledoc """
  Relay support for Absinthe.

  - Global Identification: See `UiGraph.Relay.Node`
  - Connection Model: See `UiGraph.Relay.Connection`
  - Mutations: See `UiGraph.Relay.Mutation`

  ## Examples

  Schemas should `use UiGraph.Relay.Schema`, eg:

  ```elixir
  defmodule Schema do
    use Absinthe.Schema
    use UiGraph.Relay.Schema

    # ...

  end
  ```

  For a type module, use `UiGraph.Relay.Schema.Notation`

  ```elixir
  defmodule Schema do
    use Absinthe.Schema.Notation
    use UiGraph.Relay.Schema.Notation

    # ...

  end
  ```

  See `UiGraph.Relay.Node`, `UiGraph.Relay.Connection`, and
  `UiGraph.Relay.Mutation` for specific macro information.
  """
end
