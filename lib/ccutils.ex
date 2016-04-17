defmodule CCUtils do
   @headers [:host, :path_or_url]

  def preprocess(line, excluded) do
    splat = line
    |> String.strip
    |> String.replace("&amp;", "&")
    |> String.split("\t")
    |> Enum.map(&String.strip/1)

    cond do
      2 != length(splat) ->
        IO.write excluded, "toomanycols " <> List.to_string(splat) <> "\n"
        %{url: :excluded}
      splat |> List.last |> String.contains?("app://") ->
        IO.write excluded, "app:// " <> List.to_string(splat) <> "\n"
        %{url: :excluded}
      true ->
        construct(splat)
    end
  end

  def filter(%{url: url}) do
    cond do
      is_bitstring(url) ->
        true
      true ->
        false
    end
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
    %{url: url, attempts: 1}
  end
end
