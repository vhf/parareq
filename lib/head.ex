defmodule Head do
  @headers [:host, :path_or_url]

  def parse(line) do
    xs = line
    |> String.split("\t")

    Enum.zip(@headers, xs)
  end

  def clean(line) do
    length(line) == 2
  end

  def construct(line) do
    cond do
      String.starts_with?(line[:path_or_url], "http") ->
        line[:path_or_url]
      true ->
        "http://" <> line[:host] <> line[:path_or_url]
    end
  end

  defp dispatch(url) do
    case HTTPoison.head(url) do
     {:ok, response} -> success(url, response)
     {:error, reason} -> {:error, [url: url, reason: reason]}
    end
  end

  defp success(url, response) do
    content_type = :proplists.get_value("Content-Type", response.headers())
    status_code = response.status_code
    {:ok, [url: url, content_type: content_type, status_code: status_code]}
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
    |> Stream.map(&String.strip/1)
    |> Stream.map(&parse(&1))
    |> Stream.filter(&clean(&1))
    |> Stream.filter(&construct(&1))
    |> ParallelStream.map(&dispatch(&1), num_workers: 10000, worker_work_ratio: 1)
    |> ParallelStream.map(&results(&1, done, fail, good), num_workers: 75, worker_work_ratio: 200)
    |> Stream.run
  end
end
