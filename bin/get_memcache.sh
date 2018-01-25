#!/bin/sh

exec 6>&1
exec >/usr/local/nagios/var/tmp/memcache.txt

expect -c"
spawn telnet 127.0.0.1 11211
expect \"\"
send \"stats\n\"
expect eof"

exec 1<&6 6<&-
