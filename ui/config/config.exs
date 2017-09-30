# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :ecto, json_library: OJSON

config :vex, nerves_socket_type: :udp

# Configures the endpoint
config :ui, UiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "xXiUX8dqEw6pF9NeLdywuyVy+h7Gq/sLN8OKnEiyWB2lKLi7UNdXggemkeBFRAAO",
  render_errors: [view: UiWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ui.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ui, ecto_repos: [Ui.Repo]

if Mix.Project.config[:target] == "host" do
config :ui, Ui.Repo, [
  adapter: Sqlite.Ecto2,
  database: "#{Mix.env}.sqlite3"
]
else
config :ui, Ui.Repo, [
  adapter: Sqlite.Ecto2,
  database: "/root/#{Mix.env}.sqlite3"
]
end

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
