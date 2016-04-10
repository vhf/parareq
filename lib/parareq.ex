defmodule ParaReq do
  use Supervisor

  @concurrency 20

  def init([state]) do
    {:ok, state}
  end

  def start(_type, _args) do
    import Supervisor.Spec
    # start streaming the input
    pid = stream
    Process.register(pid, :queue)

    # start the result server
    pid = spawn(fn -> ParaReq.ResultListener.start end)
    Process.register(pid, :result_listener)

    # start the hackney pool
    :application.set_env(:hackney, :use_default_pool, false)
    :hackney_pool.start_pool(:connection_pool, [
      timeout: 5_000,
      max_connections: @concurrency
    ])

    children = [
      Cache.child_spec,
      worker(ParaReq.Pool, [@concurrency])
    ]
    opts = [strategy: :one_for_one, name: ParaReq.Supervisor]
    ret = Supervisor.start_link(children, opts)

    # start pooling requests
    ParaReq.Pool.start(@concurrency)
    ret
  end

  def stream do
    excluded = File.open!("./output/0_excluded", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    {:ok, pid} = BlockingQueue.start_link(round(@concurrency*2))
    File.stream!("./input", [:utf8])
    |> Stream.map(&CCUtils.preprocess(&1, excluded))
    |> Stream.filter(&CCUtils.filter(&1))
    |> BlockingQueue.push_stream(pid)
    pid
  end
end
