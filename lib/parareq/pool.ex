defmodule ParaReq.Pool do
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  defp pool_name() do
    :worker_pool
  end

  def init(args) do
    pid = spawn(fn -> ParaReq.RequestListener.start end)
    Process.register(pid, :request_listener)
    pid = spawn(fn -> ParaReq.ResultListener.start end)
    Process.register(pid, :result_listener)

    worker_state = %{}

    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, ParaReq.Pool.Worker},
      {:size, 0},
      {:max_overflow, 50_000} # var
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
    # :ok = :hackney_pool.start_pool(:connection_pool, [
    #   timeout: 120_000, # var
    #   max_connections: 40_000 # var
    # ])
    Enum.each(1..10_000, fn _ -> # var
      spawn(fn ->
        dispatch_worker
      end)
    end)
  end

  def replace_worker do
    spawn(fn -> dispatch_worker end)
  end

  def dispatch_worker do
    try do
      :poolboy.transaction(
        pool_name(),
        fn(pid) -> ParaReq.Pool.Worker.request(pid, []) end,
        1_000 # var timeout in ms
      )
    rescue
      _ -> nil # replace_worker
    catch
      _, _ -> nil# replace_worker
    end
    replace_worker
  end
end
