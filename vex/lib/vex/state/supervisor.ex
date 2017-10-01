defmodule Vex.State.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def maybe_start_child(module) do
    case Supervisor.start_child(__MODULE__, worker(module, [], [restart: :transient])) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        {:ok, pid}
      {:error, :already_present} ->
        Supervisor.restart_child(__MODULE__, module)
      error ->
        error
    end
  end

  # def maybe_start_subscriber() do
  #   # result =
  #   case Supervisor.start_child(__MODULE__, worker(Vex.State.Subscriber, [], [restart: :transient])) do
  #     {:ok, pid} ->
  #       {:ok, pid}
  #     {:error, {:already_started, pid}} ->
  #       {:ok, pid}
  #     error ->
  #       error
  #   end
  #   # case result do
  #   #   {:ok, pid} ->


  #   # {:error, {:already_started, #PID<0.1034.0>}}
  #   # worker(Vex.State.Subscriber, [], restart: :permanent)
    
  #   # start_child(supervisor, child_spec_or_args)
  # end

  @impl Supervisor
  def init([]) do
    # Define workers and child supervisors to be supervised
    children = [
      worker(Vex.State.Autostart, [], restart: :permanent),
      supervisor(Vex.State.Event, [], restart: :permanent),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
