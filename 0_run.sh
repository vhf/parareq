#!/bin/bash
MIX_ENV=prod mix compile --force
MIX_ENV=prod nice -n 0 elixir -pa _build/prod/consolidated --no-halt --erl "\
+A 1024 \
-smp enable \
+K true \
+P 134217727 \
+S 15:15 \
-sname rss
+e 256000 \
+Q 65535 \
-spp true \
-kernel inet_dist_listen_min 10000 \
-kernel inet_dist_listen_max 65000 \
+-kernel inet_default_listen_options [{nodelay,true},{sndbuf,16384},{recbuf,4096}] \
-kernel inet_default_connect_options [{nodelay,true}] \
+t 10485760 \
+fnu \
+hms 8192 \
+hmbs 8192 \
-env ERL_MAX_ETS_TABLES 256000 \
-env ERTS_MAX_PORTS 1048576 \
-env ERL_FULLSWEEP_AFTER 1000 \
+zdbbl 2097151" -S mix
