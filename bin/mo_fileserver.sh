#!/bin/sh

. conf/globle.cfg
. bin/functions.sh

########################################################################
# FileServer监控
########################################################################

self_check fileServer
echo $$ > var/run/fileServer.pid


echo -n "$time " >> var/log/fileServer.log
FileServer=`ps -ef | grep FileServer | grep -v grep`
if [ -z "$FileServer" ];then
    message="$hostip:$hostname:FileServer is down"
    sendmsg "$message" "$Phone_list" "$prog"
    echo "`date +%Y%m%d-%X` $hostip:$hostname: FileServer is down" >> var/log/fileServer.log
else
    echo "`date +%Y%m%d-%X` $hostip:$hostname: FileServer is OK" >> var/log/fileServer.log
fi


rm -f tmp/fileServer.tmp.*
rm -f var/run/fileServer.pid
