defmodule ParaReq.Logger do
  require Logger
  use GenEvent

  def init(_) do
    Logger.info("Initializing #{__MODULE__}")
    tried = File.open!("./output/1_tried", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    good = File.open!("./output/2_good", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    error = File.open!("./output/2_error", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    exception = File.open!("./output/2_exception", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    {:ok, %{
      tried: tried,
      good: good,
      error: error,
      exception: exception
    }}
  end

  def handle_event({:tried, %{url: url, attempts: attempts}}, state) do
    %{tried: file} = state
    IO.write(file, "#{attempts}\t#{url}\n")
    {:ok, state}
  end

  def handle_event({:done, %{attempts: attempts, url: url, content_type: content_type, code: code}}, state) do
    %{good: file} = state
    IO.write(file, "#{code} (#{attempts})\t#{url}\t#{content_type}\n")
    {:ok, state}
  end

  def handle_event({:error, %{attempts: attempts, url: url, reason: reason}}, state) do
    %{error: file} = state
    IO.write(file, "(#{attempts}) #{reason}\t#{url}\n")
    if attempts < max_attempts do
      BlockingQueue.push :blocking_queue, %{attempts: attempts + 1, url: url}
    end
    Cache.inc(:errors)
    if reason == "connect_timeout" do
      Cache.inc(:timeouts)
    end
    {:ok, state}
  end

  def handle_event({:exception, %{attempts: attempts, url: url}}, state) do
    %{exception: file} = state
    IO.write(file, "(#{attempts}) exception\t#{url}\n")
    if attempts < max_attempts do
      BlockingQueue.push :blocking_queue, %{attempts: attempts + 1, url: url}
    end

    {:ok, state}
  end

  def terminate(_, %{tried: tried, good: good, error: error, exception: exception}) do
    Logger.info("Closing log files.")
    File.close(tried)
    File.close(good)
    File.close(error)
    File.close(exception)
  end

  defp max_attempts, do: Application.get_env(:parareq, :max_attempts)
end
