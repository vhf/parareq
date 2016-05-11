defmodule ParaReq do
  use Supervisor

  def init([state]) do
    {:ok, state}
  end

  def start(_type, _args) do
    import Supervisor.Spec
    # start streaming the input
    pid = stream
    Process.register(pid, :queue)
    # {:ok, manager} = GenEvent.start_link()
    # Process.register(manager, :manager)

    children = [
      worker(GenEvent, [[name: :manager]]),
      # worker(ParaReq.Logger, [ParaReq.LoggerWatcher, [name: ParaReq.Logger]]),
      worker(ParaReq.LoggerWatcher, [:manager]),
      Cache.child_spec,
      supervisor(ParaReq.Pool, [concurrency])
    ]
    options = [
      strategy: :one_for_one,
      intensity: 10,
      period: 1,
      name: ParaReq.Supervisor
    ]
    Supervisor.start_link(children, options)
    {:ok, self}
  end

  def stream do
    excluded = File.open!("./output/0_excluded", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    {:ok, pid} = BlockingQueue.start_link(round(concurrency*5))
    File.stream!("./input", [:utf8])
    |> Stream.map(&CCUtils.preprocess(&1, excluded))
    |> Stream.filter(&CCUtils.filter/1)
    |> BlockingQueue.push_stream(pid)
    pid
  end

  defp concurrency, do: Application.get_env(:parareq, :concurrency)
end
