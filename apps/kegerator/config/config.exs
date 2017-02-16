# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.Project.config[:target]}.exs"

config :nerves, :firmware,
  rootfs_additions: "config/rootfs",
  fwup_conf: "config/fwup.conf"

key_mgmt = System.get_env("NERVES_NETWORK_KEY_MGMT") || "WPA-PSK"

config :kegerator, :wlan0,
  ssid: System.get_env("NERVES_NETWORK_SSID"),
  psk: System.get_env("NERVES_NETWORK_PSK"),
  key_mgmt: String.to_atom(key_mgmt)

config :kegerator, :temperature,
  temperature: 46,
  drift: 1,
  relay_pin: 5
