ParaReq
=======

Experimenting various strategies to fire concurrent HEAD requests. Just for fun.

### Architecture

1. BlockingQueue is a queue containing a constant amount of URLs streamed to it. Whenever we'd like to get a new URL to work on, we can simply pop it, and the queue will refill.
2. We spawn thousands of workers in a poolboy pool.
3. Thousands of connections are started in hackney pool.
4. ResultListener starts, whenever a httpoison request completes or times out, it will send ResultListener what to write and ResultListener will decide where to write it.
