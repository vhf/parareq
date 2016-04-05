defmodule Pool.Requester do
  defp success(url, response) do
    content_type = :proplists.get_value("Content-Type", response.headers())
    status_code = response.status_code
    case content_type do
      :undefined ->  {:ok, [url: url, content_type: "undefined", status_code: status_code]}
      _ -> {:ok, [url: url, content_type: content_type, status_code: status_code]}
    end
  end

  def head(url) do
    result = HTTPoison.head(url, [], [hackney: [follow_redirect: false]])
    case result do
     {:ok, response} -> success(url, response)
     {:error, %HTTPoison.Error{id: _, reason: reason}} -> {:error, [url: url, reason: Atom.to_string(reason)]}
     {:error, reason} -> {:error, [url: url, reason: reason]}
     _ -> {:error, [url: url, reason: "drown"]}
    end
  end
end
