defmodule ParaReq.ResultListener do
  def start do
    tried = File.open!("./output/1_tried", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    good = File.open!("./output/2_good", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    error = File.open!("./output/2_error", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    exception = File.open!("./output/2_exception", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])

    for _ <- Stream.cycle([:ok]) do
      receive do
        {:tried, %{n: n, url: url}} ->
          Cache.inc(:reqs_done)
          IO.write tried, "#{n}\t#{url}\n"

        {:done, %{n: n, url: url, content_type: content_type, code: code}} ->
          Cache.inc(:reqs_done)
          IO.write good, "#{n}\t#{code}\t#{url}\t#{content_type}\n"

        {:error, %{n: n, url: url, reason: reason}} ->
          Cache.inc(:reqs_done)
          if reason == "connect_timeout" do
            Cache.inc(:timeout)
          end
          IO.write error, "#{n}\t#{reason}\t#{url}\n"

        {:exception, %{n: n, url: url}} ->
          Cache.inc(:reqs_done)
          IO.write exception, "#{n}\texception\t#{url}\n"

        after
          100 ->
            :ok
      end
    end
  end
end
