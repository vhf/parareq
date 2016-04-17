use Mix.Config

config :parareq,
  concurrency: 50_000,
  watch_freq: 5, # seconds
  max_attempts: 5
