defmodule ParaReq.Pool do
  require Logger

  @timeout 20_000
  @max_connections 50_000

  def start_link(args) do
    Logger.info("Starting link #{__MODULE__}")
    GenServer.start_link(__MODULE__, args)
  end

  def init(count_children) do
    import Supervisor.Spec, warn: false
    Logger.info("Initializing #{__MODULE__}")
    :application.set_env(:hackney, :max_connections, @max_connections)
    :application.set_env(:hackney, :timeout, @timeout)
    :application.set_env(:hackney, :use_default_pool, false)

    :wpool.start_sup_pool(:requester_pool, [
      overrun_warning: :infinity,
      workers: count_children
    ])

    children = [
      worker(Task, [fn -> ParaReq.Pool.Stats.watch end])
    ]
    options = [
      strategy: :one_for_one,
      name: ParaReq.Pool
    ]
    Supervisor.start_link(children, options)
  end

  def dead do
    require IEx
    # IEx.pry
    pool = :wpool.stats(:requester_pool)
    alive = Enum.reduce(pool[:workers], 0, fn {_, xs}, acc ->
      case Keyword.has_key?(xs, :task) do
        true -> acc + 1
        false -> acc + 0
      end
    end)
    dead_count = concurrency - alive
    Cache.inc(:dead_count, 0)
    dead_count
  end

  def create_workers(n) do
    Enum.each(1..n, fn _ ->
      Cache.inc(:spawned_count, 1)
      :wpool_worker.call(:requester_pool, ParaReq.Pool.Worker, :perform, [])
    end)
  end

  def start do
    Enum.each(1..1_000, fn x ->
      case dead do
        0 -> :timer.sleep(1)
        n -> create_workers(n)
      end
      :timer.sleep(50)
      if rem(x, 500) == 0 do
        IO.puts "#{x} already done"
      end
    end)
    :ok
  end

  defp concurrency, do: Application.get_env(:parareq, :concurrency)
end
