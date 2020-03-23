defmodule Annotations.Schema.Mixfile do
  use Mix.Project

  def project do
    [app: :annotations_schema,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [mod: {Annotations.Schema ,[]},extra_applications: [:logger, :postgrex, :ecto, :annotations, :pg_insert_stage]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [ {:postgrex, ">= 0.0.0"},
      {:ecto_sql, "~> 3.2"},
      {:annotations, path: "../annotations"},
      {:pg_insert_stage, path: "../pg_insert_stage"}
    ]
  end
end
