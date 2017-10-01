defmodule Ui.VCR.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def play(cassette_id) do
    id = {Ui.VCR.Play, cassette_id}
    child_spec = worker(Ui.VCR.Play, [cassette_id], [
      id: id,
      restart: :transient
    ])
    case Supervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        {:ok, pid}
      {:error, :already_present} ->
        Supervisor.restart_child(__MODULE__, id)
      error ->
        error
    end
  end

  def record(cassette_id) do
    id = {Ui.VCR.Record, cassette_id}
    child_spec = worker(Ui.VCR.Record, [cassette_id], [
      id: id,
      restart: :transient
    ])
    case Supervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        {:ok, pid}
      {:error, :already_present} ->
        Supervisor.restart_child(__MODULE__, id)
      error ->
        error
    end
  end

  # def maybe_start_child(module) do
  #   case Supervisor.start_child(__MODULE__, worker(module, [], [restart: :transient])) do
  #     {:ok, pid} ->
  #       {:ok, pid}
  #     {:error, {:already_started, pid}} ->
  #       {:ok, pid}
  #     {:error, :already_present} ->
  #       Supervisor.restart_child(__MODULE__, module)
  #     error ->
  #       error
  #   end
  # end

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
    :ok = cleanup_cassettes!()

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Registry, [[keys: :unique, name: Ui.VCR.Registry]], [restart: :permanent]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  @doc false
  defp cleanup_cassettes!() do
    cassettes = Ui.Repo.all(Ui.Data.Cassette)
    cleanup_cassettes!(cassettes)
  end

  @doc false
  defp cleanup_cassettes!([%Ui.Data.Cassette{ pid: nil } | cassettes]) do
    cleanup_cassettes!(cassettes)
  end
  defp cleanup_cassettes!([cassette = %Ui.Data.Cassette{ pid: pid, play_at: nil, stop_at: nil } | cassettes]) when is_binary(pid) do
    changeset = Ui.Data.Cassette.changeset(cassette, %{
      blank: true,
      pid: nil,
      data: nil,
      play_at: nil,
      start_at: nil,
      stop_at: nil
    })
    _result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:cassette, changeset)
      |> Ui.Repo.transaction()
    cleanup_cassettes!(cassettes)
  end
  defp cleanup_cassettes!([cassette = %Ui.Data.Cassette{ pid: pid, play_at: play_at, start_at: start_at, stop_at: stop_at } | cassettes]) when is_binary(pid) and play_at != nil and start_at != nil and stop_at != nil do
    changeset = Ui.Data.Cassette.changeset(cassette, %{
      pid: nil,
      play_at: nil
    })
    _result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:cassette, changeset)
      |> Ui.Repo.transaction()
    cleanup_cassettes!(cassettes)
  end
  defp cleanup_cassettes!([]) do
    :ok
  end
end


# defmodule Ui.VCR.Supervisor do

#   def start_link() do
#     Registry.start_link([
#       keys: :unique,
#       name: __MODULE__
#     ])
#   end

# end

# {:ok, _} = Registry.start_link(keys: :unique, name: Registry.ViaTest)
# name = {:via, Registry, {Registry.ViaTest, "agent"}}
# {:ok, _} = Agent.start_link(fn -> 0 end, name: name)