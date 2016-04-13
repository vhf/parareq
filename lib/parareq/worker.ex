defmodule ParaReq.Pool.Worker do
  @headers [{"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2700.0 Safari/537.36"}]
  @conn_timeout 5_000
  @recv_timeout 5_000

  def perform do
    url = BlockingQueue.pop :queue
    send :result_listener, {:tried, %{url: url}}
    Cache.inc(:reqs_alive)
    req =
      try do
        url
        |> HTTPoison.head(@headers, [
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
              |> HTTPoison.head(@headers, [
                timeout: @conn_timeout,
                recv_timeout: @recv_timeout,
                hackney: [pool: :connection_pool]
              ])
          end
      end
    case req do
      {:ok, %HTTPoison.Response{headers: headers, status_code: code}} ->
        if (content_type = :proplists.get_value("content-type", headers)) == :undefined do
          content_type = "undefined"
        end
        code = code |> Integer.to_string
        send :result_listener, {:done, %{url: url, content_type: content_type, code: code}}
      {:error, %HTTPoison.Error{reason: {at, msg}}} ->
        send :result_listener, {:error, %{url: url, reason: Atom.to_string(at) <> ": " <> List.to_string(msg)}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        send :result_listener, {:error, %{url: url, reason: Atom.to_string(reason)}}
      {:error, reason} when is_atom(reason) ->
        send :result_listener, {:error, %{url: url, reason: Atom.to_string(reason)}}
      {:error, reason} when is_bitstring(reason) ->
        send :result_listener, {:error, %{url: url, reason: reason}}
      {:error, _} ->
        send :result_listener, {:error, %{url: url, reason: "unmatched reason"}}
      _ ->
        send :result_listener, {:exception, %{url: url}}
    end
    Cache.inc(:reqs_alive, -1)
    Cache.inc(:reqs_done)
    perform
  end
end
