#!/bin/bash
AWK=/usr/bin/awk

n=`netstat -an | $AWK -v start=1 -v end=65535 ' $NF ~ /TIME_WAIT|ESTABLISHED/ && $4 !~ /127\.0\.0\.1/ {
    if ($1 ~ /\./)
            {sip=$1}
    else {sip=$4}

    if ( sip ~ /:/ )
            {d=2}
    else {d=5}

    split( sip, a, /:|\./ )

    if ( a[d] >= start && a[d] <= end ) {
            ++connections;
            }
    }
    END {print connections}'`
echo "$n connections"
echo
netstat -nat | awk '{print $6}' | sort | uniq -c | sort -n

echo
echo "conntrack count:"
sudo cat /proc/sys/net/netfilter/nf_conntrack_count
