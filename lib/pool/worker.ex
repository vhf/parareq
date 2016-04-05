defmodule Pool.Worker do
  use GenServer

  def start_link([]) do
    :gen_server.start_link(__MODULE__, [], [])
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(data, _from, state) do
    result = Pool.Requester.head(data)
    {:reply, result, state}
  end

  def request(pid, data) do
    :gen_server.call(pid, data)
  end
end
