defmodule Vex.Robot.Server.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @impl Supervisor
  def init([]) do
    # Define workers and child supervisors to be supervised
    children = [
      worker(Vex.Robot.Server.State, [], restart: :permanent),
      worker(Vex.Robot.Server.Socket, [], restart: :permanent),
      worker(Vex.Robot.Server, [], restart: :permanent)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
