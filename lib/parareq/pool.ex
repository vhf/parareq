defmodule ParaReq.Pool do
  @timeout 10_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(concurrency) do
    connection_pool_options = [
      {:timeout, @timeout},
      {:max_connections, concurrency}
    ]
    :hackney_pool.start_pool(:connection_pool, connection_pool_options)
    :application.set_env(:hackney, :max_connections, @max_connections)
    :application.set_env(:hackney, :timeout, @timeout)
    :application.set_env(:hackney, :use_default_pool, false)
    HTTPoison.start

    :wpool.start_sup_pool(:requester_pool, [
      overrun_warning: :infinity,
      workers: concurrency
    ])

    children = []
    options = [
      strategy: :one_for_one,
      name: ParaReq.Pool
    ]
    Supervisor.start_link(children, options)
  end

  def start(concurrency) do
    spawn(fn -> ParaReq.Pool.Stats.watch end)
    Enum.each(1..concurrency, fn _ ->
      :wpool_worker.cast(:requester_pool, ParaReq.Pool.Worker, :perform, [])
      :timer.sleep(25)
    end)
    :ok
  end
end
