defmodule ParaReq.Pool.Worker do
  @headers [{"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2700.0 Safari/537.36"}]
  @conn_timeout 8_000
  @recv_timeout 5_000

  def perform do
    url = BlockingQueue.pop :queue
    send :tried, {:tried, %{url: url}}
    Cache.inc(:reqs_alive)
    fun = fn url -> url
      |> HTTPoison.head(@headers, [
        timeout: @conn_timeout,
        recv_timeout: @recv_timeout,
        hackney: [pool: :connection_pool]
      ])
    end
    req =
      try do
        fun.(url)
      rescue
        e in CaseClauseError ->
          case e do
            %CaseClauseError{term: {:error, :bad_request}} ->
              fun.(url |> String.replace("http://", "https://"))
          end
      end
    case req do
      {:ok, %HTTPoison.Response{headers: headers, status_code: code}} ->
        if (content_type = :proplists.get_value("Content-Type", headers)) == :undefined do
          content_type = "undefined"
        end
        code = code |> Integer.to_string
        send :good, {:done, %{url: url, content_type: content_type, code: code}}
      {:error, %HTTPoison.Error{reason: {at, msg}}} ->
        send :error, {:error, %{url: url, reason: Atom.to_string(at) <> ": " <> List.to_string(msg)}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        send :error, {:error, %{url: url, reason: Atom.to_string(reason)}}
      {:error, reason} when is_atom(reason) ->
        send :error, {:error, %{url: url, reason: Atom.to_string(reason)}}
      {:error, reason} when is_bitstring(reason) ->
        send :error, {:error, %{url: url, reason: reason}}
      {:error, _} ->
        send :error, {:error, %{url: url, reason: "unmatched reason"}}
      _ ->
        send :exception, {:exception, %{url: url}}
    end
    Cache.inc(:reqs_alive, -1)
    Cache.inc(:reqs_done)
    perform
  end
end
