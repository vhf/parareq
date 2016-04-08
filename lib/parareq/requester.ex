defmodule ParaReq.Pool.Requester do
  @headers [{"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2700.0 Safari/537.36"}]

  def head(%{url: url}) do
    :timer.sleep(2_000)
    # send :result_listener, {:tried, %{url: url}}
    # req = HTTPoison.head(url, @headers, [
    #   timeout: 15_000,
    #   recv_timeout: 3_000,
    #   hackney: [follow_redirect: false, pool: :connection_pool]
    # ])
    #
    # case req do
    #   {:ok, %HTTPoison.Response{headers: headers, status_code: code}} ->
    #     if (content_type = :proplists.get_value("Content-Type", headers)) == :undefined do
    #       content_type = "undefined"
    #     end
    #     code = code |> Integer.to_string
    #     send :result_listener, {:done, %{url: url, content_type: content_type, code: code}}
    #   {:error, %HTTPoison.Error{reason: {at, msg}}} ->
    #     send :result_listener, {:error, %{url: url, reason: Atom.to_string(at) <> ": " <> List.to_string(msg)}}
    #   {:error, %HTTPoison.Error{reason: reason}} ->
    #     send :result_listener, {:error, %{url: url, reason: Atom.to_string(reason)}}
    #   {:error, reason} ->
    #     send :result_listener, {:error, %{url: url, reason: reason}}
    #   _ ->
    #     IO.inspect req
    # end
  end
end
