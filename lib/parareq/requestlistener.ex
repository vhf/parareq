defmodule ParaReq.RequestListener do
  def start do
    # all live requests
    for _ <- Stream.cycle([:ok]) do
      receive do
        # req started, url and id returned
        {:started, %{id: reference, url: url}} ->
          map = Cache.get(reference)
          Cache.put(reference, :url, url)

        # req successful, headers returned
        %HTTPoison.AsyncHeaders{id: reference, headers: headers} ->
          if (content_type = :proplists.get_value("Content-Type", headers)) == :undefined do
            content_type = "undefined"
          end
          Cache.put(reference, :content_type, content_type)

        # req status, headers returned
        %HTTPoison.AsyncStatus{id: reference, code: code} ->
          code = code |> Integer.to_string
          Cache.put(reference, :code, code)

        # req finished, write result
        %HTTPoison.AsyncEnd{id: reference} ->
          send :result_listener, {:done, Cache.get(reference)}
          Cache.del(reference)

        # req couldn't start because reason
        {:error, %{url: url, reason: reason}} ->
          send :result_listener, {:error, %{url: url, reason: reason}}

        # req threw, id returned
        {:exception, %{url: url}} ->
          send :result_listener, {:exception, %{url: url}}
      end
    end
  end
end
