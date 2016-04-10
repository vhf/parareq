ParaReq
=======

Experimenting various strategies to fire concurrent HTTP requests. Just for fun.

The goal of this project is to create an Elixir program able to make complete HTTP requests as fast as possible.

In order to generate a suitable input file and to answer your own HTTP requests locally, see [parareq-helloserver](https://github.com/vhf/parareq-helloserver).

### Architecture

1. BlockingQueue is a queue containing a constant amount of URLs streamed to it. Whenever we'd like to get a new URL to work on, we can simply pop it, and the queue will refill.
2. We spawn thousands of workers in a poolboy pool.
3. Thousands of connections are started in hackney pool.
4. ResultListener starts, whenever a httpoison request completes or times out, it will send ResultListener what to write and ResultListener will decide where to write it.

### Scripts

* `0_run.sh` runs ParaReq on `./input`. Every 5s, ParaReq logs to its console the average requests per second over the last 5s and the current number of open HTTP requests.
* `1_rps.sh` must be run as root, it watches the number of requests per second.
* `2_out.sh` resets the output files and watches the output directory, logging the number of results per second over 10s.
* `3_stats.sh` shows various stats such as request results, open connections, unused ports.
