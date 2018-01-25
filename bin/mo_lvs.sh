#! /bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

########################################################################
# mo_lvs
########################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

ps -ef|grep mo_lvs.py|grep -v grep > /dev/null 2>&1
if [ $? -ne 0 ];then
    status=1
    nohup python ./bin/mo_lvs.py >/dev/null 2>&1 &
    ps -ef|grep mo_lvs.py|grep -v grep > /dev/null 2>&1
    if [ $? -ne 0 ];then
        status=3
         message="$mydate $hostname mo_lvs.py is down and restart fail"
    else
         message="$mydate $hostname mo_lvs.py is down but restart ok"
    fi
fi

echo "{'hostname':'$hostname','date':'$mydate','msg':'$message','status':'$status'}"

rm -f var/run/$server_name.pid
