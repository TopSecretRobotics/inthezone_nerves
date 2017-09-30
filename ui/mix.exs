defmodule Ui.Mixfile do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  def project do
    [
      app: :ui,
      version: "0.0.1",
      elixir: "~> 1.5",
      target: @target,
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Ui.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe, "~> 1.4.0-rc"},
      {:absinthe_phoenix, "~> 1.4.0-rc"},
      {:absinthe_plug, "~> 1.4.0-rc"},
      {:absinthe_relay, github: "absinthe-graphql/absinthe_relay", branch: "next"},
      {:cowboy, "~> 1.0"},
      {:ecto, "~> 2.2"},
      {:gen_stage, "~> 0.12"},
      {:gettext, "~> 0.13"},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:phoenix_pubsub, "~> 1.0"},
      {:sqlite_ecto2, "~> 2.2"},
      {:vex, path: "../vex"}
    ]
  end
end
