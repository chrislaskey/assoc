use Mix.Config

# Set the log level
#
# The order from most information to least:
#
#   :debug
#   :info
#   :warn
#
config :logger, level: :info

config :assoc,
  ecto_repos: [Assoc.Test.Repo]

config :assoc, Assoc.Test.Repo,
  username: System.get_env("ASSOC_TEST_POSTGRES_USER"),
  password: System.get_env("ASSOC_TEST_POSTGRES_PASS"),
  database: System.get_env("ASSOC_TEST_POSTGRES_DB"),
  hostname: System.get_env("ASSOC_TEST_POSTGRES_HOST"),
  port: System.get_env("ASSOC_TEST_POSTGRES_PORT"),
  pool: Ecto.Adapters.SQL.Sandbox
