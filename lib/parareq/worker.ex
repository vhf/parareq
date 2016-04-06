defmodule ParaReq.Pool.Worker do
  use GenServer

  def start_link(state) do
    :gen_server.start_link(__MODULE__, state, [])
  end

  def init(state) do
    # IO.puts List.to_string(:erlang.pid_to_list(self)) <> " init"
    {:ok, state}
  end

  def handle_call(arg, from, state) do
    counter = Map.get(state, :counter)
    # if counter > 0 do
    #    IO.puts List.to_string(:erlang.pid_to_list(self)) <> " is looping"
    # else
    #   IO.puts List.to_string(:erlang.pid_to_list(self)) <> " is working"
    # end

    url = state
    |> Map.get(:qid)
    |> BlockingQueue.pop

    state
    |> Map.delete(:qid)
    |> Map.delete(:counter)
    |> Map.put(:url, url)
    |> ParaReq.Pool.Requester.head

    if counter < 25 do
      :timer.sleep(50)
      new_state = state
      |> Map.update(:counter, 0, &(&1 + 1))
      handle_call(arg, from, new_state)
    end
    # IO.puts "reached " <> Integer.to_string(counter)
    {:reply, :im_done, state}
  end

  def request(pid, data) do
    :gen_server.call(pid, data)
  end
end
