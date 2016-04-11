defmodule ParaReq.Pool.Worker do
  use GenServer

  @conn_timeout 5_000
  @recv_timeout 5_000

  def start_link(state) do
    :gen_server.start_link(__MODULE__, state, [])
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(%{n: n}, _from, _data) do
    url = BlockingQueue.pop :queue
    send :result_listener, {:tried, %{n: n, url: url}}
    Cache.inc(:reqs_alive)
    req =
      try do
        url
        |> HTTPoison.head([], [
          timeout: @conn_timeout,
          recv_timeout: @recv_timeout,
          hackney: [pool: :connection_pool]
        ])
      rescue
        e in CaseClauseError ->
          case e do
            %CaseClauseError{term: {:error, :bad_request}} ->
              url
              |> String.replace("http://", "https://")
              |> HTTPoison.head([], [
                timeout: @conn_timeout,
                recv_timeout: @recv_timeout,
                hackney: [pool: :connection_pool]
              ])
          end
      end
    case req do
      {:ok, %HTTPoison.Response{headers: headers, status_code: code}} ->
        if (content_type = :proplists.get_value("Content-Type", headers)) == :undefined do
          content_type = "undefined"
        end
        code = code |> Integer.to_string
        send :result_listener, {:done, %{n: n, url: url, content_type: content_type, code: code}}
      {:error, %HTTPoison.Error{reason: {at, msg}}} ->
        send :result_listener, {:error, %{n: n, url: url, reason: Atom.to_string(at) <> ": " <> List.to_string(msg)}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        send :result_listener, {:error, %{n: n, url: url, reason: Atom.to_string(reason)}}
      {:error, reason} when is_atom(reason) ->
        send :result_listener, {:error, %{n: n, url: url, reason: Atom.to_string(reason)}}
      {:error, reason} when is_bitstring(reason) ->
        send :result_listener, {:error, %{n: n, url: url, reason: reason}}
      {:error, _} ->
        send :result_listener, {:error, %{n: n, url: url, reason: "unmatched reason"}}
      _ ->
        send :result_listener, {:exception, %{n: n, url: url}}
    end
    Cache.inc(:reqs_alive, -1)
    Cache.inc(:reqs_done)
    {:reply, :done, nil}
  end

  def request(pid, %{n: n}) do
    :gen_server.call(pid, %{n: n})
  end
end
