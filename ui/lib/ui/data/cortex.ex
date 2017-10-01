defmodule Ui.Data.Cortex do
  use Ecto.Schema

  @type t() :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :backup_battery, :float
    field :connected, :boolean
    field :main_battery, :float
    field :ticks, :integer
  end
end
