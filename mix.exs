defmodule Assoc.MixProject do
  use Mix.Project

  def project do
    [
      app: :assoc,
      version: "0.1.0",
      build_path: "./_build",
      config_path: "./config/config.exs",
      deps_path: "./deps",
      lockfile: "./mix.lock",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      description: description(),
      package: package(),

      # Docs
      name: "Assoc",
      source_url: "https://github.com/chrislaskey/assoc",
      docs: [
        main: "Assoc",
        extras: ["README.md"]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/setup", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    default_options = [
      extra_applications: [:logger]
    ]

    case Mix.env() do
      :test -> Keyword.put(default_options, :mod, {Assoc.Test.Application, []})
      _ -> default_options
    end
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.0", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp description do
    "An easy way to manage many_to_many, has_many and belongs_to Ecto associations"
  end

  defp package() do
    [
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/chrislaskey/assoc"}
    ]
  end
end
