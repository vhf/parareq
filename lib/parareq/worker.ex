defmodule ParaReq.Pool.Worker do
  require Logger
  @headers [{"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2700.0 Safari/537.36"}]
  @conn_timeout 8_000
  @recv_timeout 5_000
  @options [
    recv_timeout: 5_000,
    max_redirect: 3
  ]


  def perform do
    %{url: url, attempts: attempts} = BlockingQueue.pop(:queue)

    # Logger.debug("#{inspect self} fetching #{url} - #{attempts}")
    Cache.inc(:tried)
    GenEvent.notify(:manager, {:tried, %{url: url, attempts: attempts}})

    case send_request(url) do
      {:ok, code, headers} ->
        if (content_type = :proplists.get_value("Content-Type", headers)) == :undefined do
          content_type = "undefined"
        end
        code = code |> Integer.to_string
        GenEvent.sync_notify(:manager, {:done, %{attempts: attempts, url: url, content_type: content_type, code: code}})
      {:error, reason} when is_atom(reason) ->
        GenEvent.sync_notify(:manager, {:error, %{attempts: attempts, url: url, reason: to_string(reason)}})
      {:error, reason} when is_bitstring(reason) ->
        GenEvent.sync_notify(:manager, {:error, %{attempts: attempts, url: url, reason: reason}})
      {:error, _} ->
        GenEvent.sync_notify(:manager, {:error, %{attempts: attempts, url: url, reason: "unmatched reason"}})
      _ ->
        GenEvent.sync_notify(:manager, {:exception, %{attempts: attempts, url: url}})
    end
    perform
  end


  def send_request(url) do
    Cache.inc(:total)
    Cache.inc(:reqs_alive)
    {:hackney_url, transport, _, _, path, _, _, _, host, port, _, _} = :hackney_url.parse_url(url)
    connection = :hackney.connect(transport, host, port, @options)
    case connection do
      {:ok, ref} ->
        res = :hackney.send_request(ref, {:head, path, @headers, []})
        :hackney.close(ref)
        Cache.inc(:reqs_alive, -1)
        res
      {:error, :eaddrnotavail} ->
        Cache.inc(:reqs_alive, -1)
        :timer.sleep(500)
        {:error, :eaddrnotavail}
      {:error, error} ->
        Cache.inc(:reqs_alive, -1)
  {:error, error}
      _ ->
        :exception
    end
  end
end
