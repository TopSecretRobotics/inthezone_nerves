defmodule SerialUdp.Application do
  use Application

  @interface Application.get_env(:serial_udp, :interface, :eth0)

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # worker(SerialUdp.Worker, [arg1, arg2, arg3]),
      worker(Task, [fn -> start_network() end], restart: :transient),
      worker(SerialUdp.Socket, [], restart: :permanent),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SerialUdp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_network() do
    Nerves.Network.setup(to_string(@interface))
  end
end
