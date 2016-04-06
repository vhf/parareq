defmodule ParaReq.Pool.Requester do
  defp success(url, response) do
    content_type = :proplists.get_value("Content-Type", response.headers())
    status_code = response.status_code
    case content_type do
      :undefined ->  {:ok, [url: url, content_type: "undefined", status_code: status_code]}
      _ -> {:ok, [url: url, content_type: content_type, status_code: status_code]}
    end
  end

  def head(%{wid: wid, url: url, fail: fail, good: good}) do
    req = HTTPoison.head(url, [], [hackney: [follow_redirect: false, pool: :connection_pool]])
    case req do
      nil -> :ok
      _ -> result =
        case req do
         {:ok, response} -> success(url, response)
         {:error, %HTTPoison.Error{id: _, reason: {at, msg}}} -> {:error, [url: url, reason: Atom.to_string(at) <> ": " <> List.to_string(msg)]}
         {:error, %HTTPoison.Error{id: _, reason: reason}} -> {:error, [url: url, reason: Atom.to_string(reason)]}
         {:error, reason} -> {:error, [url: url, reason: reason]}
         _ -> {:error, [url: url, reason: "drown"]}
        end
        write_results(wid, result, fail, good)
    end
  end

  defp write_results(wid, result, fail, good) do
    {kw, data} = result
    case kw do
     :ok -> IO.write good, "#{wid}\t#{data[:status_code]}\t#{data[:url]}\t#{data[:content_type]}\n"
     :error -> IO.write fail, "#{wid}\t#{data[:reason]}\t#{data[:url]}\n"
    end
    :ok
  end
end
