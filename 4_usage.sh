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

open=`sudo netstat -pltu | grep LISTEN | grep -v tcp6 | wc -l`
left=$((65536-open))

echo "$left free ports left"
