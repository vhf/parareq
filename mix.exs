defmodule Head.Mixfile do
  use Mix.Project

  def project do
    [app: :head,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: Main, emu_args: "+P 10000000"],
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
      {:dogma, "~> 0.1", only: :dev},
      {:credo, "~> 0.3", only: [:dev, :test]},
      {:nile, "~> 0.1.3"}
    ]
  end
end
