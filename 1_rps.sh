#!/bin/bash
tcpflow -p -c -i eth0 port 80 2>/dev/null | grep -oE '(HEAD) .* HTTP/1.[01]|Host: .*' | pv -i5 -ltr >/dev/null

