defmodule Vex.Robot.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @impl Supervisor
  def init([]) do
    # Define workers and child supervisors to be supervised
    children = [
      worker(Vex.Robot.IO, [], restart: :permanent)
    ]

    children =
      cond do
        Code.ensure_loaded?(Vex.Robot.NervesSocket) ->
          children ++ [
            worker(Vex.Robot.NervesSocket, [], restart: :permanent)
          ]
        Application.get_env(:vex, :nerves_socket_type) == :udp ->
          children ++ [
            worker(Vex.Robot.UdpSocket, [], restart: :permanent)
          ]
        true ->
          children ++ [
            supervisor(Vex.Robot.Server.Supervisor, [], restart: :permanent)
          ]
      end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
