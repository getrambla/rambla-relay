defmodule RamblaRelay.MixProject do
  use Mix.Project

  def project do
    [
      app: :rambla_relay,
      version: "0.1.0",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      releases: [rambla_relay: [include_executables_for: [:unix]]],
      deps: deps()
    ]
  end

  def application,
    do: [extra_applications: [:logger, :syn, :cowboy], mod: {RamblaRelay.Application, []}]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_environment), do: ["lib"]

  defp deps do
    [
      {:cowboy, "~> 2.17"},
      {:dns_cluster, "~> 0.2.0"},
      {:jason, "~> 1.4"},
      {:syn, "~> 3.4"},
      {:websockex, "~> 0.4", only: :test}
    ]
  end
end
