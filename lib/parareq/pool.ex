defmodule ParaReq.Pool do
  @timeout 150_000
  @max_connections 64_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(concurrency) do
    connection_pool_options = [
      {:timeout, @timeout},
      {:max_connections, @max_connections}
    ]
    :hackney_pool.start_pool(:connection_pool, connection_pool_options)
    :application.set_env(:hackney, :max_connections, @max_connections)
    :application.set_env(:hackney, :timeout, @timeout)
    :application.set_env(:hackney, :use_default_pool, false)
    HTTPoison.start

    :wpool.start_sup_pool(:requester_pool, [
      overrun_warning: :infinity,
      workers: concurrency
    ]) # random_worker, next_worker, available_worker

    children = []
    options = [
      strategy: :one_for_one,
      name: ParaReq.Pool
    ]
    Supervisor.start_link(children, options)
  end

  def dead(concurrency) do
    pool = :wpool.stats(:requester_pool)
    alive = Enum.reduce(pool[:workers], 0, fn {_, xs}, acc ->
      case Keyword.has_key?(xs, :task) do
        true -> acc + 1
        false -> acc + 0
      end
    end)
    concurrency - alive
  end

  def create_workers(n) do
    Enum.each(1..n, fn _ ->
      :wpool_worker.cast(:requester_pool, ParaReq.Pool.Worker, :perform, [])
      :timer.sleep(10)
    end)
  end

  def start(concurrency) do
    # :observer.start
    spawn(fn -> ParaReq.Pool.Stats.watch end)
    for _ <- Stream.cycle([:ok]) do
      case dead(concurrency) do
        0 -> :timer.sleep(500)
        n -> create_workers(n)
      end
    end
    :ok
  end
end
