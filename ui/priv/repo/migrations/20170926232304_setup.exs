defmodule Ui.Repo.Migrations.CreateMotors do
  use Ecto.Migration

  def up() do
    # create table(:motors, primary_key: false) do
    #   add :id, :integer, null: false, primary_key: true
    #   add :index, :integer, null: false
    #   add :ticks, :integer, null: false, default: 0
    #   add :value, :integer, null: false, default: 0
    # end

    create table(:cassettes) do
      add :name, :string, null: false
      add :blank, :boolean, null: false, default: true
      add :pid, :blob
      add :data, :blob
      add :play_at, :timestamp
      add :start_at, :timestamp
      add :stop_at, :timestamp
      timestamps()
    end

    create table(:drives) do
      add :name, :string, null: false
      add :northeast_motor, :integer
      add :northwest_motor, :integer
      add :southeast_motor, :integer
      add :southwest_motor, :integer
      add :northeast_reversed, :boolean
      add :northwest_reversed, :boolean
      add :southeast_reversed, :boolean
      add :southwest_reversed, :boolean
    end

    create table(:config, primary_key: false) do
      add :id, :integer, null: false, primary_key: true
      add :drive_id, references(:drives, type: :integer)
    end

    flush()

    # motor_entries =
    #   for id <- 0..9, into: [] do
    #     %{
    #       id: id,
    #       index: id,
    #       ticks: 0,
    #       value: 0
    #     }
    #   end
    # {10, _} =
    #   Ui.Repo.insert_all("motors", motor_entries)

    now = DateTime.utc_now()

    cassette_entries =
      for n <- 1..20, into: [] do
        %{
          name: "Cassette ##{n}",
          inserted_at: now,
          updated_at: now
        }
      end
    {20, _} =
      Ui.Repo.insert_all("cassettes", cassette_entries)

    {1, _} = Ui.Repo.insert_all("drives", [%{
      name: "starstruck",
      northeast_motor: 1,
      northwest_motor: 8,
      southeast_motor: 9,
      southwest_motor: 0,
      northeast_reversed: false,
      northwest_reversed: true,
      southeast_reversed: true,
      southwest_reversed: true
    }])

    {1, _} = Ui.Repo.insert_all("config", [%{ id: 0, drive_id: 1 }])

    true
  end

  def down() do
    drop table(:config)
    drop table(:drives)
    drop table(:cassettes)
    # drop table(:motors)
  end
end
