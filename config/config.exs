use Mix.Config

config :parareq,
  concurrency: 1_000,
  # concurrency: 1,
  watch_freq: 5, # seconds
  max_attempts: 5
