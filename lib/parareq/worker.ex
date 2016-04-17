defmodule ParaReq.Pool.Worker do
  @headers [{"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2700.0 Safari/537.36"}]
  @conn_timeout 10_000
  @recv_timeout 10_000

  def perform do
    for _ <- Stream.cycle([:ok]) do
      %{url: url, attempts: attempts} = BlockingQueue.pop :queue
      Cache.inc(:reqs_alive)
      Cache.inc(:reqs_done)
      fun = fn url -> url
        |> HTTPoison.head(@headers, [
          timeout: @conn_timeout,
          recv_timeout: @recv_timeout,
          hackney: [pool: :connection_pool, max_redirect: 3]
        ])
      end
      req =
        try do
          send :tried, {:tried, %{url: url, attempts: attempts}}
          fun.(url)
        rescue
          e in CaseClauseError ->
            case e do
              %CaseClauseError{term: {:error, :bad_request}} ->
                url = url |> String.replace("http://", "https://")
                send :tried, {:tried, %{url: url, attempts: attempts}}
                fun.(url)
            end
        catch
          x -> {:exception, x}
        end
      case req do
        {:ok, %HTTPoison.Response{headers: headers, status_code: code}} ->
          if (content_type = :proplists.get_value("Content-Type", headers)) == :undefined do
            content_type = "undefined"
          end
          code = code |> Integer.to_string
          send :good, {:done, %{attempts: attempts, url: url, content_type: content_type, code: code}}
        {:error, %HTTPoison.Error{reason: {at, msg}}} ->
          send :error, {:error, %{attempts: attempts, url: url, reason: Atom.to_string(at) <> ": " <> List.to_string(msg)}}
        {:error, %HTTPoison.Error{reason: reason}} ->
          send :error, {:error, %{attempts: attempts, url: url, reason: Atom.to_string(reason)}}
        {:error, reason} when is_atom(reason) ->
          send :error, {:error, %{attempts: attempts, url: url, reason: Atom.to_string(reason)}}
        {:error, reason} when is_bitstring(reason) ->
          send :error, {:error, %{attempts: attempts, url: url, reason: reason}}
        {:error, _} ->
          send :error, {:error, %{attempts: attempts, url: url, reason: "unmatched reason"}}
        _ ->
          send :exception, {:exception, %{attempts: attempts, url: url}}
      end
      Cache.inc(:reqs_alive, -1)
    end
  end
end
