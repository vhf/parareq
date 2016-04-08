defmodule ParaReq.Pool.Worker do
  use GenServer

  def start_link(state) do
    :gen_server.start_link(__MODULE__, state, [])
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(%{n: n}, _from, data) do
    url = :queue |> BlockingQueue.pop

    %{url: url, n: n} |> ParaReq.Pool.Requester.head

    {:reply, :done, data}
  end

  def request(pid, %{n: n}) do
    :gen_server.call(pid, %{n: n})
  end
end
