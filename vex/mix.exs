defmodule Vex.Mixfile do
  use Mix.Project

  def project do
    [app: :vex,
     version: "0.1.0",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      mod: {Vex.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:gen_state_machine, "~> 2.0"},
      {:ojson, "~> 1.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:serial_framing_protocol, github: "potatosalad/erlang-serial_framing_protocol", branch: "master"}
    ]
  end
end
