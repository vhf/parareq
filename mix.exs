defmodule ParaReq.Mixfile do
  use Mix.Project

  def project do
    [app: :head,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: ParaReq.App, emu_args: "+P 10000000"],
     deps: deps]
  end

  def application do
    [
      mod: {ParaReq.App, []},
      applications: [:logger, :httpoison, :poolboy]
    ]
  end

  def escript do
    [main_module: ParaReq.App]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.2"},
      {:poolboy, "~> 1.5"},
      {:mem, "~> 0.2.0"},
      {:blocking_queue, "~> 1.0"}
    ]
  end
end
