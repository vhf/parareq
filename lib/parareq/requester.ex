defmodule ParaReq.Pool.Requester do
  @headers [{"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2700.0 Safari/537.36"}]

  def head(%{n: n, url: url}) do
    send :result_listener, {:tried, %{n: n, url: url}}
    req =
      try do
        url
        |> HTTPoison.head(@headers, [
          timeout: 14_000,
          recv_timeout: 14_000,
          hackney: [follow_redirect: false, pool: :connection_pool]
        ])
      rescue
        e in CaseClauseError ->
          case e do
            %CaseClauseError{term: {:error, :bad_request}} ->
              url
              |> String.replace("http://", "https://")
              |> HTTPoison.head(@headers, [
                timeout: 14_000,
                recv_timeout: 14_000,
                hackney: [follow_redirect: false, pool: :connection_pool]
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
      {:error, reason} ->
        send :result_listener, {:error, %{n: n, url: url, reason: "unmatched reason"}}
      _ ->
        send :result_listener, {:exception, %{n: n, url: url}}
    end
  end
end
