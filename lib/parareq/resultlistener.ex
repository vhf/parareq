defmodule ParaReq.ResultListener do
  def tried do
    tried_file = File.open!("./output/1_tried", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    for _ <- Stream.cycle([:ok]) do
      receive do
        {:tried, %{url: url, attempts: attempts}} ->
          IO.write tried_file, "#{attempts}\t#{url}\n"
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
        {:done, %{attempts: attempts, url: url, content_type: content_type, code: code}} ->
          IO.write good_file, "#{code} (#{attempts})\t#{url}\t#{content_type}\n"
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
        {:error, %{attempts: attempts, url: url, reason: reason}} ->
          if attempts < max_attempts do
            BlockingQueue.push :queue, %{attempts: attempts + 1, url: url}
          end
          Cache.inc(:errors)
          if reason == "connect_timeout" do
            Cache.inc(:timeouts)
          end
          IO.write err_file, "(#{attempts}) #{reason}\t#{url}\n"
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
        {:exception, %{attempts: attempts, url: url}} ->
          if attempts < max_attempts do
            BlockingQueue.push :queue, %{attempts: attempts + 1, url: url}
          end

          IO.write exc_file, "(#{attempts}) exception\t#{url}\n"
        after
          10_000 ->
            :ok
      end
    end
  end

  defp max_attempts, do: Application.get_env(:parareq, :max_attempts)
end
