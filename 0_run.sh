#!/bin/bash
MIX_ENV=prod mix compile
MIX_ENV=prod elixir -pa _build/prod/consolidated --no-halt --erl "-smp enable +K true +P 134217727 +S 16:16 -kernel inet_dist_listen_min 2048 -kernel inet_dist_listen_max 65535 +zdbbl 65536 +e 256000" -S mix
