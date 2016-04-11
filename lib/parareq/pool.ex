defmodule ParaReq.Pool do
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(concurrency) do
    worker_initial_state = %{}

    worker_pool_config = [
      {:name, {:local, :worker_pool}},
      {:worker_module, ParaReq.Pool.Worker},
      {:size, concurrency},
      {:max_overflow, 0}
    ]

    connection_pool_options = [
      {:timeout, 10_000},
      {:max_connections, 60_000}
    ]

    :hackney_pool.start_pool(:connection_pool, connection_pool_options)
    HTTPoison.start

    children = [
      :poolboy.child_spec(:worker_pool, worker_pool_config, worker_initial_state)
    ]

    :application.set_env(:hackney, :max_connections, 60_000)
    :application.set_env(:hackney, :timeout, 10_000)
    :application.set_env(:hackney, :use_default_pool, false)

    # IO.inspect Application.get_all_env(:hackney)
    options = [
      strategy: :one_for_one,
      intensity: 10,
      period: 1,
      name: ParaReq.Pool
    ]

    Supervisor.start_link(children, options)
  end

  def start do
    spawn(fn -> ParaReq.Pool.Stats.watch end)
    pid = spawn(fn -> dispatcher end)
    Process.register(pid, :dispatcher)
    :global.sync
    Enum.each(1..7, fn _ ->
      spawn(fn ->
        pid = Process.whereis(:dispatcher)
        if pid == nil do
          pid = spawn(fn -> dispatcher end)
          Process.register(pid, :dispatcher)
        end
        for _ <- Stream.cycle([:ok]) do
          send :dispatcher, :spawn
          :timer.sleep 3
        end
      end)
      :timer.sleep 1_000
    end)
  end

  def dispatcher do
    for _ <- Stream.cycle([:ok]) do
      receive do
        :spawn ->
          spawn(fn ->
            try do
              :poolboy.transaction(
                :worker_pool,
                fn(pid) -> ParaReq.Pool.Worker.request(pid, %{n: 1}) end,
                50
              )
            rescue
              _ -> nil # nothing, repeater on its way
            catch
              _, _ -> nil # same
            end
            send :dispatcher, :spawn
          end)
        after
          50 ->
            :ok
      end
    end
  end
end
