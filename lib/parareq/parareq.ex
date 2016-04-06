defmodule ParaReq do
  use Supervisor

  def init([state]) do
    {:ok, state}
  end

  def start(_type, _args) do
    import Supervisor.Spec
    {:ok, qid} = stream

    children = [
      worker(ParaReq.Pool, [qid])
    ]
    opts = [strategy: :one_for_one, name: ParaReq.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stream do
    bad = File.open!("./output/bad", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    {:ok, qid} = BlockingQueue.start_link(100_000)  #ttsize
    File.stream!("./input", [:utf8])
    |> Stream.map(&CCUtils.split(&1))
    |> Stream.filter(&CCUtils.clean(&1, bad))
    |> Stream.map(&CCUtils.construct(&1))
    |> BlockingQueue.push_stream(qid)
    # IO.puts "Queue ready!"
    {:ok, qid}
  end
end
