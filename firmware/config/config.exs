# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Customize the firmware. Uncomment all or parts of the following
# to add files to the root filesystem or modify the firmware
# archive.

# config :nerves, :firmware,
#   rootfs_overlay: "rootfs_overlay",
#   fwup_conf: "config/fwup.conf"

config :nerves_network,
  regulatory_domain: "US"

config :nerves_network, :default,
  wlan0: [
    ssid: "Metropolis",
    psk: "Clark Kent",
    key_mgmt: :"WPA-PSK"
  ],
  eth0: [
    ipv4_address_method: :dhcp
  ]

# config :firmware, interface: :eth0
config :firmware, interface: :wlan0

config :absinthe, log: false
config :logger, level: :error

config :ui, UiWeb.Endpoint,
  http: [port: 80],
  url: [host: "192.168.86.200", port: 80],
  secret_key_base: "QvXVdSngFcyZVlofQyzmfSBBSPDxXqurdOnvVLUHlk4MSBElzGe0hJNFsJYNjYeR",
  root: Path.dirname(__DIR__),
  server: true,
  render_errors: [view: UiWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ui.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :ui, ecto_repos: [Ui.Repo]

config :ui, Ui.Repo, [
  adapter: Sqlite.Ecto2,
  database: "/root/#{Mix.env}.sqlite3"
]

config :nerves_firmware_ssh,
  authorized_keys: [
    "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIBn0KisbG467o35uOGF0Vew9JFyjr4lwXu5f6oK4MoNdH4Yky7pUybkPy74A39in6Ip5g4U3Qni78HidAGC9lLYW7KIuCl2vfyKIvBRVGCE2VBT9ae4MYQBYkvg6kHN2XMdahbj0mlyhSXhQ6rExYxSZhsOGTpZZEk5vYB7SZH3hQ=="
  ]

# Use bootloader to start the main application. See the bootloader
# docs for separating out critical OTP applications such as those
# involved with firmware updates.
config :bootloader,
  init: [:nerves_runtime],
  app: :firmware

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.Project.config[:target]}.exs"
