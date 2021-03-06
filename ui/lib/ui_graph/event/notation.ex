defmodule UiGraph.Event.Notation do

  @moduledoc """
  Macros used to define Event-related schema entities
  """

  alias Absinthe.Schema.Notation

  @doc """
  Define a event interface, field, or object type for a schema.
  """
  defmacro event({:interface, _, _}, [do: block]) do
    do_interface(__CALLER__, block)
  end
  defmacro event({:field, _, _}, [do: block]) do
    do_field(__CALLER__, block)
  end
  defmacro event({:object, _, [identifier | rest]}, [do: block]) do
    do_object(__CALLER__, identifier, List.flatten(rest), block)
  end

  #
  # INTERFACE
  #

  # Add the event interface
  defp do_interface(env, block) do
    env
    |> Notation.recordable!(:interface)
    |> record_interface!(:event, [], block)
    Notation.desc_attribute_recorder(:event)
  end

  @doc false
  # Record the event interface
  def record_interface!(env, identifier, attrs, block) do
    Notation.record_interface!(
      env,
      identifier,
      Keyword.put_new(attrs, :description, "An object representing an event"),
      [interface_body(), block]
    )
  end

  # An id field is automatically configured
  defp interface_body() do
    quote do
      field :id, non_null(:id), description: "The id of the event."
      field :source, non_null(:string), description: "The source of the event."
    end
  end

  #
  # FIELD
  #

  # Add the event field
  defp do_field(env, block) do
    env
    |> Notation.recordable!(:field)
    |> record_field!(:event, [type: :event], block)
  end

  @doc false
  # Record the event field
  def record_field!(env, identifier, attrs, block) do
    Notation.record_field!(
      env,
      identifier,
      Keyword.put_new(attrs, :description, "Fetches an event given its ID"),
      [field_body(), block]
    )
  end

  # An id arg is automatically added
  defp field_body do
    quote do
      @desc "The id of an event."
      arg :id, non_null(:id)
      @desc "The source of an event."
      arg :source, non_null(:string)

      middleware {Absinthe.Relay.Node, :resolve_with_global_id}
    end
  end

  #
  # OBJECT
  #

  # Define a event object type
  defp do_object(env, identifier, attrs, block) do
    record_object!(env, identifier, attrs, block)
  end

  @doc false
  # Record a event object type
  def record_object!(env, identifier, attrs, block) do
    name = attrs[:name] || identifier |> Atom.to_string |> Absinthe.Utils.camelize
    Notation.record_object!(
      env,
      identifier,
      Keyword.delete(attrs, :id_fetcher),
      [object_body(name, attrs[:id_fetcher]), block]
    )
    Notation.desc_attribute_recorder(identifier)
  end

  # Automatically add:
  # - An id field that resolves to the generated global ID
  #   for an object of this type
  # - A declaration that this implements the event interface
  defp object_body(_name, id_fetcher) do
    name = :event
    quote do
      @desc "The ID of an object"
      field :id, non_null(:id) do
        resolve Absinthe.Relay.Node.global_id_resolver(unquote(name), unquote(id_fetcher))
      end
      field :source, non_null(:string)
      interface :event
    end
  end

  defmacro __using__(_opts) do
    quote do
      import UiGraph.Event.Notation, only: :macros
    end
  end

end
