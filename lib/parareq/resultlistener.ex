defmodule ParaReq.ResultListener do
  def tried do
    tried_file = File.open!("./output/1_tried", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    for _ <- Stream.cycle([:ok]) do
      receive do
        {:tried, %{url: url}} ->
          IO.write tried_file, "#{url}\n"
        after
          10_000 ->
            :ok
      end
    end
  end

  def good do
    good_file = File.open!("./output/2_good", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    for _ <- Stream.cycle([:ok]) do
      receive do
        {:done, %{url: url, content_type: content_type, code: code}} ->
          IO.write good_file, "#{code}\t#{url}\t#{content_type}\n"
        after
          10_000 ->
            :ok
      end
    end
  end

  def error do
    err_file = File.open!("./output/2_error", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    for _ <- Stream.cycle([:ok]) do
      receive do
        {:error, %{url: url, reason: reason}} ->
          if reason == "connect_timeout" do
            Cache.inc(:timeout)
          end
          IO.write err_file, "#{reason}\t#{url}\n"
        after
          10_000 ->
            :ok
      end
    end
  end

  def exception do
    exc_file = File.open!("./output/2_exception", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    for _ <- Stream.cycle([:ok]) do
      receive do
        {:exception, %{url: url}} ->
          IO.write exc_file, "exception\t#{url}\n"
        after
          10_000 ->
            :ok
      end
    end
  end
end
