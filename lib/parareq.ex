defmodule ParaReq do
  require Logger

  def init([state]) do
    {:ok, state}
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = [
      # GenEvent manager
      worker(GenEvent, [[name: :manager]]),
      # Managed Logger server
      worker(ParaReq.LoggerWatcher, [:manager]),
      # Streamed input BlockingQueue
      worker(BlockingQueue, [round(concurrency*5), [name: :blocking_queue]]),
      # KV store for stats
      Cache.child_spec,
      # Worker pool supervisor
      supervisor(ParaReq.Pool, [concurrency])
    ]
    opts = [
      strategy: :one_for_one,
      intensity: 10,
      period: 1,
      name: ParaReq.Supervisor
    ]
    # Start all children
    stat = Supervisor.start_link(children, opts)
    # Start streame
    stream
    # Start working?
    if autostart do
      Logger.info("Start working!")
      ParaReq.Pool.start
    end
    stat
  end

  def stream do
    Logger.info("Filling up BlockingQueue")
    excluded = File.open!("./output/0_excluded", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    File.stream!("./input", [:utf8])
    |> Stream.map(&CCUtils.preprocess(&1, excluded))
    |> Stream.filter(&CCUtils.filter/1)
    |> BlockingQueue.push_stream(:blocking_queue)
  end

  defp autostart, do: Application.get_env(:parareq, :autostart)
  defp concurrency, do: Application.get_env(:parareq, :concurrency)
end
