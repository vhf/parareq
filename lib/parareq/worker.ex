defmodule ParaReq.Pool.Worker do
  use GenServer

  def start_link(state) do
    :gen_server.start_link(__MODULE__, state, [])
  end

  def init(state) do
    # IO.puts List.to_string(:erlang.pid_to_list(self)) <> " init"
    {:ok, state}
  end

  def handle_call(_arg, _from, %{qid: qid, done: done, fail: fail, good: good}) do
    url = qid |> BlockingQueue.pop
    wid = List.to_string(:erlang.pid_to_list(self))
    IO.write done, wid <> "\t" <> url <> "\n"

    try do
      %{wid: wid, url: url, fail: fail, good: good} |> ParaReq.Pool.Requester.head
    catch
      _,_ -> {:reply, :failed, %{qid: qid, done: done, fail: fail, good: good}}
    end

    {:reply, :done, %{qid: qid, done: done, fail: fail, good: good}}
  end

  def request(pid, data) do
    :gen_server.call(pid, data)
  end
end
