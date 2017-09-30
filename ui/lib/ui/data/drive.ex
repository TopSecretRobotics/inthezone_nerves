defmodule Ui.Data.Drive do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ui.Repo

  @type t() :: %__MODULE__{}

  @primary_key {:id, :integer, autogenerate: false, read_after_writes: false}
  schema "drives" do
    field :name, :string
    belongs_to :ne, Ui.Data.Motor
    belongs_to :nw, Ui.Data.Motor
    belongs_to :se, Ui.Data.Motor
    belongs_to :sw, Ui.Data.Motor
  end

  # @doc false
  # def changeset(struct = %__MODULE__{}, attrs) do
  #   struct
  #   |> cast(attrs, [
  #     :ticks,
  #     :value
  #   ])
  #   |> validate_required([:ticks, :value])
  # end
end
