defmodule ParaReq.Pool do
  def start_link(qid) do
    GenServer.start_link(__MODULE__, qid)
  end

  defp pool_name() do
    :worker_pool
  end

  def init(qid) do
    done = File.open!("./output/done", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    fail = File.open!("./output/fail", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    good = File.open!("./output/good", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])

    state = %{qid: qid, done: done, fail: fail, good: good}

    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, ParaReq.Pool.Worker},
      {:size, 0},
      {:max_overflow, 30_000} #ttsize
    ]

    children = [
      :poolboy.child_spec(pool_name(), poolboy_config, state)
    ]

    options = [
      strategy: :one_for_one,
      name: ParaReq.Pool
    ]
    Supervisor.start_link(children, options)
  end

  def start do
    :ok = :hackney_pool.start_pool(:connection_pool, [mod_metrics: :folsom, timeout: 864_000_000, max_connections: 15_000])
    Enum.each(1..2_000, fn _ -> #ttsize
      spawn(fn -> dispatch_worker end)
    end)
  end

  def replace_worker do
    IO.puts List.to_string(:erlang.pid_to_list(self)) <> " requeued"
    spawn(fn -> dispatch_worker end)
  end

  def dispatch_worker do
    try do
      :poolboy.transaction(
        pool_name(),
        fn(pid) -> ParaReq.Pool.Worker.request(pid, []) end,
        15_000 # timeout in ms
      )
    rescue
      _ -> nil # replace_worker
    catch
      _, _ -> nil# replace_worker
    end
    replace_worker
  end
end
