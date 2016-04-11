defmodule ParaReq.Pool do
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  defp pool_name(x) do
    String.to_atom("worker_pool" <> x)
  end

  def init(concurrency) do
    worker_state = %{}

    poolboy_config = [
      worker_module: ParaReq.Pool.Worker,
      size: concurrency,
      max_overflow: 0,
      strategy: :lifo
    ]

    connection_pool_options = [
      {:timeout, 10_000},
      {:max_connections, 60_000}
    ]

    :hackney_pool.start_pool(:connection_pool, connection_pool_options)
    HTTPoison.start

    children = [
      :poolboy.child_spec(pool_name("1"), poolboy_config ++ [name: [local: pool_name("1")]], worker_state),
      :poolboy.child_spec(pool_name("2"), poolboy_config ++ [name: [local: pool_name("2")]], worker_state),
      :poolboy.child_spec(pool_name("3"), poolboy_config ++ [name: [local: pool_name("3")]], worker_state),
      :poolboy.child_spec(pool_name("4"), poolboy_config ++ [name: [local: pool_name("4")]], worker_state)
    ]

    :application.set_env(:hackney, :max_connections, 60_000)
    :application.set_env(:hackney, :timeout, 10_000)
    :application.set_env(:hackney, :use_default_pool, false)

    IO.inspect Application.get_all_env(:hackney)
    options = [
      strategy: :one_for_one,
      intensity: 10,
      period: 1,
      name: ParaReq.Pool
    ]

    Supervisor.start_link(children, options)
  end

  def start(concurrency) do
    spawn(fn -> ParaReq.Pool.Stats.watch end)
    Enum.each(1..4, fn x ->
      Enum.each(1..concurrency, fn n ->
        spawn(fn ->
          dispatch_worker(n, Integer.to_string(x))
        end)
      end)
    end)
  end

  def dispatch_worker(n, x) do
    try do
      :poolboy.transaction(
        pool_name(x),
        fn(pid) -> ParaReq.Pool.Worker.request(pid, %{n: n}) end,
        :infinity
      )
    rescue
      _ -> nil # do nothing, repeater on its way
    catch
      _, _ -> nil # same
    end
    dispatch_worker(n, x)
  end
end
