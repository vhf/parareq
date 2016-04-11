#!/bin/bash
MIX_ENV=prod mix compile
MIX_ENV=prod nice -n 19 elixir -pa _build/prod/consolidated --no-halt --erl "+A 1024 \
-smp enable \
+K true \
+P 134217727 \
+S 16:8 \
-sname rss
+e 256000" \
--erl "-env ERL_MAX_PORTS 500000" \
--erl "+Q 262144 -spp true" \
--erl "-kernel inet_dist_listen_min 10000" \
--erl "-kernel inet_dist_listen_max 65000" \
--erl "-kernel inet_default_connect_options [{nodelay,true}]" \
--erl "+t 10485760 +fnu +hms 8192 +hmbs 8192 \
-env ERL_MAX_ETS_TABLES 256000 \
+zdbbl 2097151" -S mix
