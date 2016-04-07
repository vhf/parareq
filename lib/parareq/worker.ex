defmodule ParaReq.Pool.Worker do
  use GenServer

  def start_link(state) do
    :gen_server.start_link(__MODULE__, state, [])
  end

  def init(state) do
    # IO.puts List.to_string(:erlang.pid_to_list(self)) <> " init"
    {:ok, state}
  end

  def handle_call(_arg, _from, %{}) do
    url = :queue |> BlockingQueue.pop

    try do
      %{url: url} |> ParaReq.Pool.Requester.head
    catch
      _,_ ->
        send :request_listener, {:exception, url}
        {:reply, :failed, %{}}
    end

    {:reply, :done, %{}}
  end

  def request(pid, data) do
    :gen_server.call(pid, data)
  end
end
