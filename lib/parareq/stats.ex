defmodule ParaReq.Pool.Stats do
  use Timex
  @freq 5 # in seconds

  def watch do
    log = File.open!("./output/3_log", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    for _ <- Stream.cycle([:ok]) do
      :timer.sleep(@freq * 1_000)
      done = round(Cache.check(:reqs_done) / @freq)
      Cache.set(:reqs_done, 0)
      alive = Cache.check(:reqs_alive)
      rel_timeouts = round(((Cache.check(:timeout) / @freq / done) * 10000)) / 100
      Cache.set(:timeout, 0)
      {:ok, time} = DateTime.now("Europe/Zurich") |> Timex.format("{ISO:Extended}")
      line = "#{time}\t#{done}/s\t#{alive}\t#{rel_timeouts}%"
      IO.puts line
      IO.write log, line <> "\n"
    end
  end
end
