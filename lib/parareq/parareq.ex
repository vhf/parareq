defmodule ParaReq do
  use Supervisor

  def init([state]) do
    {:ok, state}
  end

  def start(_type, _args) do
    import Supervisor.Spec
    pid = stream
    Process.register(pid, :queue)
    pid = spawn(fn -> ParaReq.RequestListener.start end)
    Process.register(pid, :request_listener)
    pid = spawn(fn -> ParaReq.ResultListener.start end)
    Process.register(pid, :result_listener)

    spawn(fn -> watch end)

    children = [
      Cache.child_spec,
      worker(ParaReq.Pool, ["args"])
    ]
    opts = [strategy: :one_for_one, name: ParaReq.Supervisor]

    Supervisor.start_link(children, opts)
  end

  def stream do
    excluded = File.open!("./output/0_excluded", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    {:ok, pid} = BlockingQueue.start_link(100_000)  #ttsize
    File.stream!("./input", [:utf8])
    |> Stream.map(&CCUtils.preprocess(&1, excluded))
    |> Stream.filter(&CCUtils.filter(&1))
    |> BlockingQueue.push_stream(pid)
    pid
  end

  def watch do
    for _ <- Stream.cycle([:ok]) do
      IO.inspect :erlang.localtime
      send :request_listener, {:op}
      send :result_listener, {:op}
      :timer.sleep(1000)
    end
  end
end
