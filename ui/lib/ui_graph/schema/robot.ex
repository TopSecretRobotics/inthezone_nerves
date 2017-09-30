defmodule UiGraph.Schema.Robot do
  use Absinthe.Schema.Notation
  # use Absinthe.Relay.Schema.Notation, :classic
  # alias UiGraph.Schema

  object :robot_queries do
    field :is_connected, non_null(:boolean) do
      resolve fn (_, _, _) ->
        {:ok, Ui.Vex.Status.connected?()}
      end
    end

    field :main_battery, non_null(:float) do
      resolve fn (_, _, _) ->
        %{ main: main_battery } = Ui.Vex.Status.batteries()
        {:ok, main_battery}
      end
    end

    field :backup_battery, non_null(:float) do
      resolve fn (_, _, _) ->
        %{ backup: backup_battery } = Ui.Vex.Status.batteries()
        {:ok, backup_battery}
      end
    end

    field :ticks, non_null(:integer) do
      resolve fn (_, _, _) ->
        {:ok, Ui.Vex.Status.ticks()}
      end
    end
  end

  object :robot_subscriptions do
    field :observe_is_connected, type: :boolean do
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
    end

    field :observe_main_battery, type: :float do
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
    end

    field :observe_backup_battery, type: :float do
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
    end

    field :observe_ticks, type: :integer do
      config fn (_args, _info) ->
        {:ok, topic: <<>>}
      end
    end
  end

end
