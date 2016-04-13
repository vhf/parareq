defmodule ParaReq do
  use Supervisor

  @concurrency 100

  def init([state]) do
    {:ok, state}
  end

  def start(_type, _args) do
    import Supervisor.Spec
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
    Supervisor.start_link(children, options)
    # start pooling requests
    ret = ParaReq.Pool.start(@concurrency)
    {ret, self}
  end
end
