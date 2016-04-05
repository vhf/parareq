defmodule Main do
  @headers [:host, :path_or_url]

  def split(line) do
    String.strip(line) |> String.split("\t")
  end

  def clean(line) do
    last = List.last(line)
    2 == length(line) and
    not ((not String.starts_with?(last, "http://") or not String.starts_with?(last, "https://")) and String.contains?(last, "://"))
  end

  def construct(line) do
    xs = Enum.zip(@headers, line)
    cond do
      String.starts_with?(xs[:path_or_url], "//") ->
        "http:" <> xs[:path_or_url]
      String.starts_with?(xs[:path_or_url], "http") ->
        xs[:path_or_url]
      String.starts_with?(xs[:path_or_url], "/") ->
        xs[:path_or_url]
      true ->
        "http://" <> xs[:host] <> "/" <> xs[:path_or_url]
    end
  end

  def validate(url) do
    case Validation.validate(url) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp results(result, done, fail, good) do
    {kw, data} = result
    case kw do
     :ok -> IO.write good, "#{data[:status_code]}\t#{data[:url]}\t#{data[:content_type]}\n"
     :error -> IO.write fail, "#{data[:reason]}\t#{data[:url]}\n"
    end
    IO.write done, "#{data[:url]}\n"
    :ok
  end

  def main(_args) do
    done = File.open!("./output/done", [:read, :write, :read_ahead, :append, :delayed_write])
    fail = File.open!("./output/fail", [:read, :write, :read_ahead, :append, :delayed_write])
    good = File.open!("./output/good", [:read, :write, :read_ahead, :append, :delayed_write])
    IO.stream(:stdio, :line)
    |> Stream.map(&split(&1))
    |> Stream.filter(&clean(&1))
    |> Stream.map(&construct(&1))
    |> Stream.filter(&validate(&1))
    |> ParallelStream.map(&Pool.request(&1), num_workers: 10000, worker_work_ratio: 1)
    |> ParallelStream.map(&results(&1, done, fail, good), num_workers: 75, worker_work_ratio: 200)
    |> Stream.run
  end
end
