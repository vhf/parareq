defmodule Pool.Requester do
  defp success(url, response) do
    content_type = :proplists.get_value("Content-Type", response.headers())
    status_code = response.status_code
    case content_type do
      :undefined ->  {:ok, [url: url, content_type: "undefined", status_code: status_code]}
      _ -> {:ok, [url: url, content_type: content_type, status_code: status_code]}
    end
  end

  def head(%{url: url, done: done, fail: fail, good: good}) do
    req = HTTPoison.head(url, [], [hackney: [follow_redirect: false]])
    result =
      case req do
       {:ok, response} -> success(url, response)
       {:error, %HTTPoison.Error{id: _, reason: reason}} -> {:error, [url: url, reason: Atom.to_string(reason)]}
       {:error, reason} -> {:error, [url: url, reason: reason]}
       _ -> {:error, [url: url, reason: "drown"]}
      end
    case result do
      nil -> :ok
      _ -> write_results(result, done, fail, good)
    end
  end

  defp write_results(result, done, fail, good) do
    {kw, data} = result
    case kw do
     :ok -> IO.write good, "#{data[:status_code]}\t#{data[:url]}\t#{data[:content_type]}\n"
     :error -> IO.write fail, "#{data[:reason]}\t#{data[:url]}\n"
    end
    IO.write done, "#{data[:url]}\n"
    :ok
  end
end
