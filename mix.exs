defmodule CoderRing.MixProject do
  use Mix.Project

  def project do
    [
      app: :coder_ring,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        ci: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        dialyzer: :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit],
        ignore: ".dialyzer_ignore.exs"
      ],

      # Docs
      name: "CoderRing",
      source_url: "https://github.com/instinctscience/coder_ring",
      homepage_url: "https://github.com/instinctscience/coder_ring",
      docs: [
        main: "CoderRing",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      # {:ecto, "~> 2.2 or ~> 3.0"},
      {:ecto_sql, "~> 3.4"},
      {:excoveralls, "~> 0.13.3", only: :test},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:postgrex, "~> 0.15", only: [:test]}
    ]
  end

  defp aliases do
    [
      ci: ["lint", "coveralls", "dialyzer"],
      lint: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
