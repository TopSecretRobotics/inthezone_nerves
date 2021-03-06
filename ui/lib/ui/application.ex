defmodule Ui.Application do
  use Application

  @otp_app :ui

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    :ok = ecto_setup!()

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Ui.Repo, []),
      # Start the endpoint when the application starts
      supervisor(UiWeb.Endpoint, []),
      # Start the absinthe subscription endpoint
      supervisor(Absinthe.Subscription, [UiWeb.Endpoint]),
      # Start your own worker by calling: Ui.Worker.start_link(arg1, arg2, arg3)
      supervisor(Ui.VCR.Supervisor, []),
      # supervisor(Ui.Vex.Event, []),
      # worker(Ui.Vex.Status, []),
      # worker(Ui.Vex.Debug, []),
      # worker(Ui.Vex.Listener, []),
      # worker(Ui.Vex.MotorState, []),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ui.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    UiWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @doc false
  def ecto_setup!() do
    repos = Application.get_env(@otp_app, :ecto_repos)
    for repo <- repos do
      :ok = ecto_repo_setup!(repo)
      :ok = ecto_repo_migrate!(repo)
    end
    :ok
  end

  @doc false
  def ecto_repo_setup!(repo) do
    db_file = Application.get_env(@otp_app, repo)[:database]
    if File.exists?(db_file) do
      :ok
    else
      :ok = repo.__adapter__.storage_up(repo.config())
    end
  end

  @doc false
  def ecto_repo_migrate!(repo) do
    opts = [all: true]
    {:ok, pid, apps} = Mix.Ecto.ensure_started(repo, opts)
    migrator = &Ecto.Migrator.run/4
    pool = repo.config[:pool]
    migrations_path = Path.join([(:code.priv_dir(@otp_app) |> to_string), "repo", "migrations"])
    migrated =
      if function_exported?(pool, :unboxed_run, 2) do
        pool.unboxed_run(repo, fn -> migrator.(repo, migrations_path, :up, opts) end)
      else
        migrator.(repo, migrations_path, :up, opts)
      end
    pid && repo.stop(pid)
    _ = Mix.Ecto.restart_apps_if_migrated(apps, migrated)
    :ok
  end
end
