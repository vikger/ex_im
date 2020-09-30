defmodule ExIm.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_im,
      version: "0.1.4",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExIm.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:local_cluster, "~> 1.2", only: [:test]}
      #      {:ex_unit_clustered_case, "~> 0.1"}
    ]
  end
end
