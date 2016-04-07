defmodule Cache do
  use Mem,
    worker_number:      50_000,    # (optional, default: 2) how many processes in worker pool
    default_ttl:        300,     # (optional, default: nil) default seconds for set/2

    maxmemory_size:     "2GB", # (optional, default: nil) max memory used, support such format: [1000, "10k", "1GB", "1000 K"]
    maxmemory_strategy: :lru,    # ([:lru, :ttl, :fifo]) strategy for cleaning memory
    persistence:        false    # (optional, default: false) whether enable persistence

  def put(key, k, v) do
    state = Cache.get(key)
    case state do
      {:err, _} ->
        Cache.set(key, Map.new |> Map.put(k, v))
      {:ok, map} ->
        Cache.set(key, map |> Map.update(k, v, fn(old) -> v end))
    end
  end
end
