defmodule Head.Mixfile do
  use Mix.Project

  def project do
    [app: :head,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: Main],
    #  default_task: "run"
     deps: deps]
  end

  def application do
    [
      mod: {Pool, []},
      applications: [:logger, :httpoison, :poolboy],
    ]
  end

  def escript do
    [main_module: Main]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.2"},
      {:poolboy, "~> 1.5"},
      {:parallel_stream, "~> 1.0.3"}
    ]
  end
end
