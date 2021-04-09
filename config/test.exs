use Mix.Config

config :coder_ring,
  ecto_repos: [CoderRing.Test.Repo],
  repo: CoderRing.Test.Repo,
  rings: [widget: [base_length: 1]]

config :coder_ring, CoderRing.Test.Repo,
  database: "coder_ring_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/priv"

config :logger, level: :warn
