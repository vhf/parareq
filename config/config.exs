use Mix.Config

config :parareq,
  # number of workers performing parallel HTTP requests
  concurrency: 500,
  # seconds between two statistics stdout lines
  watch_freq: 5,
  # number of retries for each failed HTTP request (fail means connection failed, it has nothing to do with HTTP status code)
  max_attempts: 5,
  # use connection pooling (true means custom pooling, false means no pooling at all, "default" means default hackney pooling)
  pooling: true,
  # max number of tcp connections kept in hackney pool, max number of concurrent tcp connections if pooling is false
  pool_size: 500,
  # pooled connections timeout in seconds
  pool_timeout: 20,
  # automatically start working
  autostart: true
