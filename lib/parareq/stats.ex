defmodule ParaReq.Pool.Stats do
  use Timex
  require Logger

  def watch do
    log = File.open!("./output/3_log", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    for _ <- Stream.cycle([:ok]) do
      :timer.sleep(freq * 1_000)
      {:ok, time} = DateTime.now("Europe/Zurich") |> Timex.format("{ISO}")
      tried = Cache.check(:tried)
      done = round(tried / freq)
      alive = Cache.check(:reqs_alive)
      dead_count = Cache.check(:dead_count)
      spawned_count = Cache.check(:spawned_count)
      count_errors = Cache.check(:errors)
      count_timeouts = Cache.check(:timeouts)
      total = Cache.check(:total)
      line =
        cond do
          tried > 0 ->
            rel_errors = round(((count_errors / tried) * 10_000)) / 100
            rel_timeouts = round(((count_timeouts / tried) * 10_000)) / 100
            "#{time} #{total}\t%d: #{done}/s\t%a: #{alive}\t%e: #{rel_errors}\t%t: #{rel_timeouts}\td: #{dead_count}\ts: #{spawned_count}"
          true ->
            "#{time} #{total}\t%d: 0/s\t%a: #{alive}\te: #{count_errors}\tt: #{count_timeouts}\td: #{dead_count}\ts: #{spawned_count}"
        end
      Logger.debug(line)
      IO.write log, line <> "\n"
      Cache.set(:tried, 0)
      Cache.set(:errors, 0)
      Cache.set(:timeouts, 0)
      Cache.set(:dead_count, 0)
      Cache.set(:spawned_count, 0)
    end
  end

  defp freq, do: Application.get_env(:parareq, :watch_freq)
end
