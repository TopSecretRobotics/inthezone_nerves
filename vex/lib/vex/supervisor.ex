defmodule Vex.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @impl Supervisor
  def init([]) do
    :vex_monitor_map = :ets.new(:vex_monitor_map, [:named_table, :public, :bag])
    :vex_priority_map = :ets.new(:vex_priority_map, [:named_table, :public, :bag])

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Vex.Event, [], restart: :permanent),
      supervisor(Vex.State.Supervisor, [], restart: :permanent),
      # worker(Vex.Logger, [], restart: :permanent),
      supervisor(Vex.Robot.Supervisor, [], restart: :permanent),
      supervisor(Vex.Local.Supervisor, [], restart: :permanent)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
