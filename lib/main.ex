defmodule Main do
  @headers [:host, :path_or_url]

  defp split(line) do
    line
    |> HtmlEntities.decode # does it work?
    |> String.strip
    |> String.split("\t")
    |> Enum.map(&String.strip/1)
  end

  defp clean(line, bad) do
    last = List.last(line)
    test =
      cond do
        2 != length(line) -> false
        length(String.split(last, "://")) > 2 -> false
        true -> true
      end

    if not test do
      IO.write bad, "unclean " <> List.to_string(line) <> "\n"
    end
    test
  end

  defp construct(line) do
    xs = Enum.zip(@headers, line)
    url =
      cond do
        # //example.com/page.html -> http://example.com/page.html
        String.starts_with?(xs[:path_or_url], "//") ->
          "http:" <> xs[:path_or_url]
        # http://example.com/page.html -> http://example.com/page.html
        String.starts_with?(xs[:path_or_url], "http") ->
          xs[:path_or_url]
        # /example.com/page.html -> http://example.com/page.html
        String.starts_with?(xs[:path_or_url], "/") ->
          "http://" <> xs[:host] <> xs[:path_or_url]
        # page.html -> http://example.com/page.html
        true ->
          "http://" <> xs[:host] <> "/" <> xs[:path_or_url]
      end
    url
  end

  defp validate(url, bad) do
    test =
      case Validation.validate(url) do
        {:ok, _} -> true
        _ -> false
      end
    if not test do
      IO.write bad, "invalid " <> url <> "\n"
    end
    test
  end

  def main(_args) do
    bad = File.open!("./output/bad", [:utf8, :read, :write, :read_ahead, :append, :delayed_write])
    :stdio
    |> IO.stream(:line)
    |> Stream.map(&split(&1))
    |> Stream.filter(&clean(&1, bad))
    |> Stream.map(&construct(&1))
    |> Stream.filter(&validate(&1, bad))
    |> Nile.pmap(&Pool.request(&1), concurrency: 100000, timeout: 60_000)
    |> Stream.run
  end
end
