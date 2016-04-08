defmodule ParaReq.ResultListener do
  def start do
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
          if reason == "connect_timeout" do
            Cache.inc(:to)
            {:ok, inc} = Cache.get(:to)
            if rem(inc, 250) == 0 do
              IO.puts Integer.to_string(inc) <> " timeouts"
            end
          end
          IO.write error, "#{reason}\t#{url}\n"

        {:exception, %{url: url}} ->
          IO.write exception, "exception\t#{url}\n"
      end
    end
  end
end
