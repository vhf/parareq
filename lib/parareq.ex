defmodule ParaReq do
  use Supervisor

  @concurrency 1_000

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

    children = [
      Cache.child_spec,
      worker(ParaReq.Pool, [@concurrency])
    ]
    options = [
      strategy: :one_for_one,
      intensity: 10,
      period: 1,
      name: ParaReq.Supervisor
    ]
    ret = Supervisor.start_link(children, options)

    # start pooling requests
    ParaReq.Pool.start
    ret
  end

  def stream do
    excluded = File.open!("./output/0_excluded", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    {:ok, pid} = BlockingQueue.start_link(round(@concurrency*5))
    File.stream!("./input", [:utf8])
    |> Stream.map(&CCUtils.preprocess(&1, excluded))
    |> Stream.filter(&CCUtils.filter(&1))
    |> BlockingQueue.push_stream(pid)
    pid
  end
end
