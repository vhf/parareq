defmodule ParaReq.Pool do
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  defp pool_name() do
    :worker_pool
  end

  def init(concurrency) do
    worker_state = %{}

    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, ParaReq.Pool.Worker},
      {:size, concurrency},
      {:max_overflow, round(concurrency*0.25)}
    ]

    children = [
      # :hackney_pool.child_spec(:connection_pool, [
      #   timeout: 2_500,
      #   max_connections: round(@concurrency*10)
      # ]),
      :poolboy.child_spec(pool_name(), poolboy_config, worker_state)
    ]

    options = [
      strategy: :one_for_one,
      name: ParaReq.Pool
    ]
    Supervisor.start_link(children, options)
  end

  def start(concurrency) do
    spawn(fn -> ParaReq.Pool.Stats.watch end)
    Enum.each(1..concurrency, fn n ->
      spawn(fn ->
        dispatch_worker n
      end)
    end)
  end

  def dispatch_worker(n) do
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
    dispatch_worker(n)
  end
end
