defmodule ParaReq.Pool.Requester do
  def head(%{url: url}) do
    req = HTTPoison.head(url, [], [stream_to: :request_listener, hackney: [follow_redirect: false, pool: :connection_pool]])
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
