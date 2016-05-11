defmodule ParaReq.Logger do
  use GenEvent

  def handle_event({:tried, %{url: url, attempts: attempts}}, parent) do
    tried_file = File.open!("./output/1_tried", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    IO.write tried_file, "#{attempts}\t#{url}\n"
    {:ok, parent}
  end
  # 
  # def handle_event({:crash, _}, parent) do
  #   IO.puts "A"
  #   :ok = :error
  #   IO.puts "B"
  #   {:ok, parent}
  # end
  #
  # def handle_event({:sleep, _}, parent) do
  #   IO.inspect self
  #   IO.puts "gone to sleep"
  #   :timer.sleep(10_000)
  #   IO.puts "done sleeping"
  #   {:ok, parent}
  # end

  def handle_event({:done, %{attempts: attempts, url: url, content_type: content_type, code: code}}, parent) do
    good_file = File.open!("./output/2_good", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    IO.write good_file, "#{code} (#{attempts})\t#{url}\t#{content_type}\n"
    {:ok, parent}
  end

  def handle_event({:error, %{attempts: attempts, url: url, reason: reason}}, parent) do
    err_file = File.open!("./output/2_error", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    if attempts < max_attempts do
      BlockingQueue.push :queue, %{attempts: attempts + 1, url: url}
    end
    Cache.inc(:errors)
    if reason == "connect_timeout" do
      Cache.inc(:timeouts)
    end
    IO.write err_file, "(#{attempts}) #{reason}\t#{url}\n"
    {:ok, parent}
  end

  def handle_event({:exception, %{attempts: attempts, url: url}}, parent) do
    exc_file = File.open!("./output/2_exception", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    if attempts < max_attempts do
      BlockingQueue.push :queue, %{attempts: attempts + 1, url: url}
    end

    IO.write exc_file, "(#{attempts}) exception\t#{url}\n"
    {:ok, parent}
  end

  defp max_attempts, do: Application.get_env(:parareq, :max_attempts)
end
