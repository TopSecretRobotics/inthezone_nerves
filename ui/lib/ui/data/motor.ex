defmodule Ui.Data.Motor do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ui.Repo

  @type t() :: %__MODULE__{}

  @primary_key {:id, :integer, autogenerate: false, read_after_writes: false}
  schema "motors" do
    field :index, :integer
    field :ticks, :integer
    field :value, :integer
  end

  @doc false
  def changeset(struct = %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, [
      :ticks,
      :value
    ])
    |> validate_required([:ticks, :value])
  end
end
