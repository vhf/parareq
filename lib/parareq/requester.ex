defmodule ParaReq.Pool.Requester do
  @headers [{"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2700.0 Safari/537.36"}]

  def head(%{url: url}) do
    req = HTTPoison.head(url, @headers, [
      timeout: 15_000,
      recv_timeout: 3_000,
      stream_to: :request_listener,
      hackney: [follow_redirect: false, pool: :connection_pool]
    ])
    # req = HTTPoison.head(url, @headers, [stream_to: :request_listener, hackney: [follow_redirect: false]])
    send :result_listener, {:tried, %{url: url}}
    case req do
      {:ok, %HTTPoison.AsyncResponse{id: reference}} ->
        send :request_listener, {:started, %{id: reference, url: url}}
      {:error, %HTTPoison.Error{id: reference, reason: {at, msg}}} ->
        send :request_listener, {:started, %{id: reference, url: url}}
        send :request_listener, {:error, %{url: url, reason: Atom.to_string(at) <> ": " <> List.to_string(msg)}}
      {:error, %HTTPoison.Error{id: reference, reason: reason}} ->
        send :request_listener, {:started, %{id: reference, url: url}}
        send :request_listener, {:error, %{url: url, reason: Atom.to_string(reason)}}
      {:error, reason} ->
        send :request_listener, {:error, %{url: url, reason: reason}}
      _ ->
        send :request_listener, {:error, %{url: url, reason: "drown"}}
    end
  end
end
