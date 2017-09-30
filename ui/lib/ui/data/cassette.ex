defmodule Ui.Data.Cassette do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ui.Repo

  @type t() :: %__MODULE__{}

  @primary_key {:id, :integer, autogenerate: false, read_after_writes: false}
  schema "cassettes" do
    field :name, :string
    field :blank, :boolean, default: true
    field :pid, :string
    field :data, :string
    field :start_at, :naive_datetime
    field :stop_at, :naive_datetime
    timestamps()
  end

  @doc false
  def changeset(struct = %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, [
      :name,
      :blank,
      :pid,
      :data,
      :start_at,
      :stop_at
    ])
    |> validate_required([
      :name,
      :blank
    ])
  end
end
