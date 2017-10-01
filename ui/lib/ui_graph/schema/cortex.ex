defmodule UiGraph.Schema.Cortex do
  use Absinthe.Schema.Notation

  object :cortex do
    field :backup_battery, non_null(:float)
    field :connected, non_null(:boolean)
    field :main_battery, non_null(:float)
    field :ticks, non_null(:integer)
  end

  object :cortex_queries do
    field :cortex, type: non_null(:cortex) do
      resolve fn (_, _, _) ->
        cortex = Ui.State.Cortex.read()
        {:ok, cortex}
      end
    end
  end

  object :cortex_subscriptions do
    field :observe_cortex, type: non_null(:cortex) do
      config fn (_args, _info) ->
        :ok = Ui.State.Cortex.observe()
        {:ok, topic: <<>>}
      end
    end
  end

end
