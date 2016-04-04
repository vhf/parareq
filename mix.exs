defmodule Head.Mixfile do
  use Mix.Project

  def project do
    [app: :head,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: Head],
    #  default_task: "run"
     deps: deps]
  end

  def application do
    [
      applications: [:logger, :httpoison],
    ]
  end

  def escript do
    [main_module: Head]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.2"},
      {:parallel_stream, "~> 1.0.3"}
    ]
  end
end
