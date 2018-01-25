#!/bin/bash

MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0

########################################################################
# mo_tripw
########################################################################

self_check $server_name
echo $$ > var/run/$server_name.pid

status=0
message="nothing"
if [ -f /usr/local/tripwire/te/agent/data/log/teagent.log ]; then

     tail -n 20 /usr/local/tripwire/te/agent/data/log/teagent.log > /tmp/tripw.log

     grep -q "ception" /tmp/tripw.log

     if [ $? -eq 0 ]; then
          message="tripw has been restarted"
         /usr/local/tripwire/te/agent/bin/twdaemon restart > /dev/null 2>&1

         #echo "`date +%Y%m%d-%X` $hostname: $message" >> /var/log/tripw.log
     fi

else
    status=1
    message="tripw isn't been installed"
    #echo "`date +%Y%m%d-%X` $hostname: $message" >> /var/log/tripw.log
fi
echo "{\"status\":\"$status\",\"hostname\":\"$hostname\",\"date\":\"$mydate\",\"msg\":\"$message\"}"
rm -f var/run/$server_name.pid