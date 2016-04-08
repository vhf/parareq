#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
tcpflow -p -c -i eth0 port 80 2>/dev/null | grep -oE '(HEAD) .* HTTP/1.[01]|Host: .*' | pv -i1 -ltr >/dev/null
