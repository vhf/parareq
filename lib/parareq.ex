defmodule ParaReq do
  require Logger

  def init([state]) do
    {:ok, state}
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = [
      worker(GenEvent, [[name: :manager]]),
      worker(ParaReq.LoggerWatcher, [:manager]),
      worker(BlockingQueue, [round(concurrency*5), [name: :blocking_queue]]),
      Cache.child_spec,
      supervisor(ParaReq.Pool, [concurrency])
    ]
    opts = [
      strategy: :one_for_one,
      intensity: 10,
      period: 1,
      name: ParaReq.Supervisor
    ]
    stat = Supervisor.start_link(children, opts)
    stream
    stat
  end

  def stream do
    Logger.info("Filling up BlockingQueue")
    excluded = File.open!("./output/0_excluded", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    File.stream!("./input", [:utf8]) |> Stream.map(&CCUtils.preprocess(&1, excluded))
    |> Stream.filter(&CCUtils.filter/1)
    |> BlockingQueue.push_stream(:blocking_queue)
  end

  defp concurrency, do: Application.get_env(:parareq, :concurrency)
end
