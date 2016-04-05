defmodule Pool do
  use Application

  defp pool_name() do
    :request_pool
  end

  def start(_type, _args) do
    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, Pool.Worker},
      {:size, 101_000},
      {:max_overflow, 5_000}
    ]

    children = [
      :poolboy.child_spec(pool_name(), poolboy_config, [])
    ]

    options = [
      strategy: :one_for_one,
      name: Pool.Supervisor
    ]

    Supervisor.start_link(children, options)
  end

  def request(url) do
    put_in_pool(url)
  end

  defp put_in_pool(url) do
    done = File.open!("./output/done", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    fail = File.open!("./output/fail", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    good = File.open!("./output/good", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    try do
      :poolboy.transaction(
        pool_name(),
        fn(pid) -> Pool.Worker.request(pid, %{url: url, done: done, fail: fail, good: good}) end,
        50_000 # timeout in ms
      )
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end
end
