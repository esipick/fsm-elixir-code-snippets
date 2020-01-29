defmodule Flight.Mixfile do
  use Mix.Project

  def project do
    [
      app: :flight,
      version: "0.0.1",
      elixir: ">= 1.9.1",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Flight.Application, []},
      extra_applications: [
        :appsignal,
        :logger,
        :runtime_tools,
        :comeonin,
        :timex,
        :bamboo,
        :scrivener_ecto,
        :scrivener_html
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib", "priv/repo/seeds"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "1.3.3"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 1.0"},

      # Flight dependencies
      {:bamboo, "~> 0.8"},
      {:bcrypt_elixir, "~> 1.0"},
      {:cowboy, "~> 1.0"},
      {:comeonin, "~> 4.0"},
      {:tzdata, "~> 0.1.8"},
      {:timex, "~> 3.2.0"},
      {:hackney, "~> 1.15.2", override: true},
      {:stripity_stripe, "~> 2.1.0"},
      {:currency_formatter, "~> 0.4"},
      {:appsignal, "~> 1.8.0"},
      {:sweet_xml, "~> 0.6"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws_sns, "~> 2.0"},
      {:scrivener_ecto, "~> 1.0"},
      {:scrivener_html, "~> 1.8"},
      {:scrivener_headers, "~> 3.1"},
      {:ecto_enum, "~> 1.3"},
      {:react_phoenix, "~> 0.6.0"},

      # Dev tools
      {:faker, "~> 0.12", only: [:dev, :test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
