defmodule ParaReq.Pool do
  require Logger

  @gen_tcp_options [
    conn_timeout: 8_000,
    recv_timeout: 5_000,
    max_redirect: 3,
  ]

  def start_link(args) do
    Logger.info("Starting link #{__MODULE__}")
    GenServer.start_link(__MODULE__, args)
  end

  def init_hackney do
    config = fn ->
      Logger.info("Configuring Hackney (disabling default pool, etc)")
      :application.set_env(:hackney, :max_connections, pool_size)
      :application.set_env(:hackney, :timeout, pool_timeout)
      :application.set_env(:hackney, :use_default_pool, false)
      true
    end
    case pooling do
      true ->
        config.()
        connection_pool_options = [
          {:timeout, pool_timeout},
          {:max_connections, pool_size}
        ]
        :hackney_pool.start_pool(:connection_pool, connection_pool_options)
        Logger.info("Setting up a custom Hackney pool (#{pool_size}, #{pool_timeout})")
      false ->
        config.()
    end
  end

  def init(count_children) do
    import Supervisor.Spec, warn: false
    Logger.info("Initializing #{__MODULE__}")

    init_hackney

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

  def create_workers(n, gen_tcp_options) do
    Enum.each(1..n, fn _ ->
      Cache.inc(:spawned_count, 1)
      :wpool_worker.cast(:requester_pool, ParaReq.Pool.Worker, :perform, [gen_tcp_options])
    end)
  end

  def start do
    gen_tcp_options = case pooling do
      true -> Keyword.merge(@gen_tcp_options, [reuseaddr: true, pool: :connection_pool])
      _ ->
        @gen_tcp_options
    end

    Enum.each(1..1_000, fn x ->
      case dead do
        0 -> :timer.sleep(1)
        n -> create_workers(n, gen_tcp_options)
      end
      :timer.sleep(50)
      if rem(x, 500) == 0 do
        Logger.debug("#{x} already done")
      end
    end)
    :ok
  end

  defp concurrency, do: Application.get_env(:parareq, :concurrency)
  defp pooling, do: Application.get_env(:parareq, :pooling)
  defp pool_size, do: Application.get_env(:parareq, :pool_size)
  defp pool_timeout, do: Application.get_env(:parareq, :pool_timeout) * 1_000
end
