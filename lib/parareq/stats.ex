defmodule ParaReq.Pool.Stats do
  use Timex

  def watch do
    log = File.open!("./output/3_log", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    for _ <- Stream.cycle([:ok]) do
      :timer.sleep(freq * 1_000)
      {:ok, time} = DateTime.now("Europe/Zurich") |> Timex.format("{ISO:Extended}")
      reqs_done = Cache.check(:reqs_done)
      done = round(reqs_done / freq)
      alive = Cache.check(:reqs_alive)
      line =
        cond do
          reqs_done > 0 ->
            rel_errors = round(((Cache.check(:errors) / freq / reqs_done) * 10_000)) / 100
            rel_timeouts = round(((Cache.check(:timeouts) / freq / reqs_done) * 10_000)) / 100
            "#{time}\t%d: #{done}/s\t%a: #{alive}\t%e: #{rel_errors}\t%t: #{rel_timeouts}"
          true ->
            count_errors = Cache.check(:errors)
            count_timeouts = Cache.check(:timeouts)
            "#{time}\t%d: 0/s\t%a: #{alive}\te: #{count_errors}\tt: #{count_timeouts}"
        end
      IO.puts line
      IO.write log, line <> "\n"
      Cache.set(:reqs_done, 0)
      Cache.set(:errors, 0)
      Cache.set(:timeouts, 0)
    end
  end

  defp freq, do: Application.get_env(:parareq, :watch_freq)
end
