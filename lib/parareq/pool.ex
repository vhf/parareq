defmodule ParaReq.Pool do
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  defp pool_name() do
    :worker_pool
  end

  def init(args) do
    worker_state = %{}

    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, ParaReq.Pool.Worker},
      {:size, 0},
      {:max_overflow, 25_000} # var
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
    :ok = :hackney_pool.start_pool(:connection_pool, [
      timeout: 120_000, # var
      max_connections: 25_000 # var
    ])
    spawn(fn -> watch end)
    Enum.each(1..5_000, fn _ -> # var
      spawn(fn ->
        dispatch_worker
      end)
    end)
  end

  def dispatch_worker do
    try do
      :poolboy.transaction(
        pool_name(),
        fn(pid) -> ParaReq.Pool.Worker.request(pid, []) end,
        20_000 # var timeout in ms
      )
    rescue
      _ -> nil # replace_worker
    catch
      _, _ -> nil# replace_worker
    end
    dispatch_worker
  end

  def watch do
    sec = File.open!("./output/0_sec", [:utf8, :read, :write, :read_ahead, :append])
    for _ <- Stream.cycle([:ok]) do
      n = Cache.check(:op_res)
      IO.write sec, Integer.to_string(n) <> "\n"
      IO.puts n
      :timer.sleep(1_000)
    end
  end
end
