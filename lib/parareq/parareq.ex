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
    |> Stream.map(&CCUtils.preprocess(&1, bad))
    |> BlockingQueue.push_stream(qid)
    {:ok, qid}
  end
end
