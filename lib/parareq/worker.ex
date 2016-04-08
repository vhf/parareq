defmodule ParaReq.Pool.Worker do
  use GenServer

  def start_link(state) do
    :gen_server.start_link(__MODULE__, state, [])
  end

  def init(state) do
    IO.puts List.to_string(:erlang.pid_to_list(self)) <> " starting"
    {:ok, state}
  end

  def handle_call(%{n: n}, _from, data) do
    url = :queue |> BlockingQueue.pop
    IO.puts List.to_string(:erlang.pid_to_list(self)) <> " handling " <> Integer.to_string(n)
    try do
      ret = %{url: url} |> ParaReq.Pool.Requester.head
    catch
      _,_ ->
        send :request_listener, {:exception, url}
        {:reply, :failed, data}
    end

    {:reply, :done, data}
  end

  def request(pid, %{n: n}) do
    :gen_server.call(pid, %{n: n})
  end
end
