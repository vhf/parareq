defmodule ParaReq.Pool do
  @concurrency 10

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  defp pool_name() do
    :worker_pool
  end

  def init(_args) do
    worker_state = %{}

    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, ParaReq.Pool.Worker},
      {:size, @concurrency},
      {:max_overflow, 0}
    ]

    children = [
      :poolboy.child_spec(pool_name(), poolboy_config, worker_state)
    ]

    options = [
      strategy: :one_for_one,
      name: ParaReq.Pool
    ]
    Supervisor.start_link(children, options)
  end

  def start do
    IO.puts "starting"
    Process.register(spawn(fn -> repeater end), :repeater)
    :ok = :hackney_pool.start_pool(:connection_pool, [
      timeout: 120_000,
      max_connections: round(@concurrency*1.1)
    ])
    spawn(fn -> ParaReq.Pool.Stats.watch end)
    Enum.each(1..@concurrency, fn n ->
      spawn(fn ->
        dispatch_worker n
        :timer.sleep(100)
      end)
    end)
  end

  def repeater do
    for _ <- Stream.cycle([:ok]) do
      receive do
        {:next, n} -> spawn(fn -> dispatch_worker n end)
      end
    end
  end

  def dispatch_worker(n) do
    Cache.inc(:reqs_done)
    Cache.inc(:reqs_alive)
    try do
      :poolboy.transaction(
        pool_name(),
        fn(pid) -> ParaReq.Pool.Worker.request(pid, %{n: n}) end,
        :infinity
      )
    rescue
      _ -> nil # do nothing, repeater on its way
    catch
      _, _ -> nil # same
    end
    Cache.inc(:reqs_alive, -1)
    send :repeater, {:next, n}
  end
end
