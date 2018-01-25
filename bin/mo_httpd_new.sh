#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

#####################################################################
# http进程监控 
#####################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

if [ ! -f tmp/mo_http_new.tmp ];then
    echo 0 > tmp/mo_http_new.tmp
fi

httpd=`pgrep -lo httpd`
if [ -z "$httpd" ];then     
    status=1
    /etc/init.d/httpd start >/dev/null 2>&1
    httpd=`pgrep -lo httpd`
    if [ -z "$httpd" ];then
        message="$mydate $hostname httpd is down and restart fail"
		status=3
    else
        message="$mydate $hostname httpd is down but restart ok"
        restart_flag=`cat tmp/mo_http_new.tmp`
        if [ $restart_flag -eq 1 ];then
            status=3
        else
            echo 1 > tmp/mo_http_new.tmp
        fi
    fi
else
    echo 0 > tmp/mo_http_new.tmp
fi

curl http://127.0.0.1:8080/server-status?auto > tmp/http.$$ 2> /dev/null

CpuLoad=`sed -n '/CPULoad/'p tmp/http.$$ |  awk -F\: '{print $2}'`
Uptime=`sed -n '/Uptime/'p tmp/http.$$ |  awk -F\: '{print $2}'`
ReqPerSec=`sed -n '/ReqPerSec/'p tmp/http.$$ |  awk -F\: '{print $2}'`
BytesPerSec=`sed -n '/BytesPerSec/'p tmp/http.$$ |  awk -F\: '{print $2}'`
BytesPerReq=`sed -n '/BytesPerReq/'p tmp/http.$$ |  awk -F\: '{print $2}'`
BusyWorkers=`sed -n '/BusyWorkers/'p tmp/http.$$ |  awk -F\: '{print $2}'`
IdleWorkers=`sed -n '/IdleWorkers/'p tmp/http.$$ |  awk -F\: '{print $2}'`
Scoreboard=`sed -n '/Scoreboard/'p tmp/http.$$ |  awk -F\: '{print $2}'`

scoreboard=`echo $Scoreboard | sed -e s'/\.//'g -e s'/\_/O/'g | awk 'BEGIN{ORS=""}{for(i=1;i<=length($0);i++) ++S[substr($0,i,1)]}END{for(a in S) print a""S[a]}'`

if [ $BusyWorkers -gt 250 ];then  
     status=3
     message="$mydate $hostname httpd busyworkers is $BusyWorkers"
fi

echo "{'hostname':'$hostname','status':'$status','CpuLoad':'$CpuLoad','Uptime':'$Uptime','ReqPerSec':'$ReqPerSec','BytesPerSec':'$BytesPerSec','BytesPerReq':'$BytesPerReq','BusyWorkers':'$BusyWorkers','IdleWorkers':'$IdleWorkers','Scoreboard':'$scoreboard','msg':'$message','date':'$mydate'}"

rm -f tmp/http*
rm -f var/run/$server_name.pid
