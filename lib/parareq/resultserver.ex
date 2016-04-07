defmodule ParaReq.ResultServer do
  def request_listener do
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

  def result_listener do
    tried = File.open!("./output/1_tried", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    good = File.open!("./output/2_good", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    error = File.open!("./output/2_error", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    exception = File.open!("./output/2_exception", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])

    for _ <- Stream.cycle([:ok]) do
      receive do
        {:tried, %{url: url}} ->
          IO.write tried, url <> "\n"

        {:done, {:ok, %{url: url, content_type: content_type, code: code}}} ->
          IO.write good, "#{code}\t#{url}\t#{content_type}\n"

        {:error, %{url: url, reason: reason}} ->
          IO.write error, "#{reason}\t#{url}\n"

        {:exception, %{url: url}} ->
          IO.write exception, "exception\t#{url}\n"
      end
    end
  end
end
