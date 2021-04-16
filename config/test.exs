use Mix.Config

config :coder_ring,
  ecto_repos: [CoderRing.Test.Repo]

config :coder_ring, CoderRing.MySimpleCoderRing,
  repo: CoderRing.Test.Repo,
  rings: [widget: [expletive_blacklist: :english], doodad: [base_length: 1]]

config :coder_ring, CoderRing.MyCoderRingProc,
  repo: CoderRing.Test.Repo,
  rings: [widget: [expletive_blacklist: :english], doodad: [base_length: 1]]

config :coder_ring, CoderRing.Test.Repo,
  database: "coder_ring_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/priv",
  timeout: 20_000

config :logger, level: :warn
