defmodule Ui.Data.Config do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ui.Repo

  @type t() :: %__MODULE__{}

  @primary_key {:id, :integer, autogenerate: false, read_after_writes: false}
  schema "config" do
    belongs_to :drive, Ui.Data.Drive
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
