#!/bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

########################################################################
#   rsync ½ø³Ì¼à¿Ø
########################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

rsync=`pgrep -lo rsync`
if [ -z "$rsync" ];then
    status=1
    rsync --daemon
    if [ -z "`pgrep -lo rsync`" ];then
        message="$mydate $hostname rsync start fail"
    else
        message="$mydate $hostname rsync start ok"
    fi
fi

echo "{'hostname':'$hostname','date':'$mydate','msg':'$message','status':'$status'}"

rm -f var/run/$server_name.pid
