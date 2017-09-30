use Mix.Config

config :ui, Ui.Repo,
  adapter: Sqlite.Ecto2,
  database: "#{Mix.env}.sqlite3"

config :ui, ecto_repos: [Ui.Repo]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
