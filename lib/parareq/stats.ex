defmodule ParaReq.Pool.Stats do
  @freq 5_000
  use Timex
  def watch do
    log = File.open!("./output/3_log", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    for _ <- Stream.cycle([:ok]) do
      done = round(Cache.check(:reqs_done)/(@freq/1_000))
      alive = Cache.check(:reqs_alive)
      Cache.set(:reqs_done, 0)
      {:ok, time} = DateTime.now("Europe/Zurich") |> Timex.format("{ISO:Extended}")
      line = "#{time}\t#{done}/s\t#{alive}"
      IO.puts line
      IO.write log, line <> "\n"
      :timer.sleep(@freq)
    end
  end
end
