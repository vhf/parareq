defmodule ParaReq.Logger do
  use GenEvent

  def handle_event({:tried, %{url: url, attempts: attempts}}, parent) do
    File.open!("./output/1_tried", [:utf8, :read, :write, :read_ahead, :append, :delayed_write], fn file ->
      IO.write(file, "#{attempts}\t#{url}\n")
    end)
    {:ok, parent}
  end

  def handle_event({:done, %{attempts: attempts, url: url, content_type: content_type, code: code}}, parent) do
    File.open!("./output/2_good", [:utf8, :read, :write, :read_ahead, :append, :delayed_write], fn file ->
      IO.write(file, "#{code} (#{attempts})\t#{url}\t#{content_type}\n")
    end)
    {:ok, parent}
  end

  def handle_event({:error, %{attempts: attempts, url: url, reason: reason}}, parent) do
    File.open!("./output/2_error", [:utf8, :read, :write, :read_ahead, :append, :delayed_write], fn file ->
      IO.write(file, "(#{attempts}) #{reason}\t#{url}\n")
    end)
    if attempts < max_attempts do
      BlockingQueue.push :blocking_queue, %{attempts: attempts + 1, url: url}
    end
    Cache.inc(:errors)
    if reason == "connect_timeout" do
      Cache.inc(:timeouts)
    end
    {:ok, parent}
  end

  def handle_event({:exception, %{attempts: attempts, url: url}}, parent) do
    File.open!("./output/2_exception", [:utf8, :read, :write, :read_ahead, :append, :delayed_write], fn file ->
      IO.write("(#{attempts}) exception\t#{url}\n")
    end)
    if attempts < max_attempts do
      BlockingQueue.push :blocking_queue, %{attempts: attempts + 1, url: url}
    end

    {:ok, parent}
  end

  defp max_attempts, do: Application.get_env(:parareq, :max_attempts)
end
