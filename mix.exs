defmodule ParaReq.Mixfile do
  use Mix.Project

  def project do
    [app: :parareq,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [
      mod: {ParaReq, []},
      applications: [:logger, :timex, :worker_pool]
    ]
  end

  defp deps do
    [
      {:mem, "~> 0.2.0"},
      {:worker_pool, "~> 1.0.4"},
      {:timex, "~> 2.1.4"},
      {:eflame, ~r/.*/, git: "https://github.com/proger/eflame.git", compile: "rebar compile"},
      {:blocking_queue, "~> 1.0"}
    ]
  end
end
