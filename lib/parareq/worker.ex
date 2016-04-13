defmodule ParaReq.Pool.Worker do
  @headers [{"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2700.0 Safari/537.36"}]
  @conn_timeout 5_000
  @recv_timeout 5_000

  def perform do
    Cache.inc(:reqs_alive)
    req =
      url
      |> HTTPoison.head(@headers, [
        timeout: @conn_timeout,
        recv_timeout: @recv_timeout,
        hackney: [pool: :connection_pool]
      ])
    Cache.inc(:reqs_alive, -1)
    Cache.inc(:reqs_done)
    perform
  end
end
