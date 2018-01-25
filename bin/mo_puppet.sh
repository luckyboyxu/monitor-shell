#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

########################################################################
# mo_puppet
########################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

puppet=`pgrep -lo puppet`
if [ ! -n "$puppet" ];then
    status=1
    /etc/init.d/puppet start >/dev/null 2>&1
    puppet=`pgrep -lo puppet`
    if [ ! -n "$puppet" ];then
        status=3
         message="$mydate $hostname puppet is down and restart fail"
    else
         message="$mydate $hostname puppet is down but restart ok"
    fi
fi

echo "{'hostname':'$hostname','date':'$mydate','msg':'$message','status':'$status'}"

rm -f var/run/$server_name.pid
