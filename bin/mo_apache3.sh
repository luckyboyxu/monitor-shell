#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

mydate=`date "+%Y-%m-%d %H:%M:%S"`
remark="nothing"
status=0

. conf/globle.cfg
. bin/functions.sh

#####################################################################
# http进程监控 
#####################################################################
self_check httpd
echo $$ > var/run/httpd.pid
curl http://127.0.0.1:8083/server-status?auto > tmp/http.$$ 2> /dev/null
CpuLoad=`sed -n '/CPULoad/'p tmp/http.$$ |  awk -F\: '{print $2}'`  
Uptime=`sed -n '/Uptime/'p tmp/http.$$ |  awk -F\: '{print $2}'` 
ReqPerSec=`sed -n '/ReqPerSec/'p tmp/http.$$ |  awk -F\: '{print $2}'` 
BytesPerSec=`sed -n '/BytesPerSec/'p tmp/http.$$ |  awk -F\: '{print $2}'` 
BytesPerReq=`sed -n '/BytesPerReq/'p tmp/http.$$ |  awk -F\: '{print $2}'` 
BusyWorkers=`sed -n '/BusyWorkers/'p tmp/http.$$ |  awk -F\: '{print $2}'` 
IdleWorkers=`sed -n '/IdleWorkers/'p tmp/http.$$ |  awk -F\: '{print $2}'` 
Scoreboard=`sed -n '/Scoreboard/'p tmp/http.$$ |  awk -F\: '{print $2}'` 

scoreboard=`echo $Scoreboard | sed -e s'/\.//'g -e s'/\_/O/'g | awk 'BEGIN{ORS=""}{for(i=1;i<=length($0);i++) ++S[substr($0,i,1)]}END{for(a in S) print a""S[a]}'`

echo -n "$time " >> var/log/httpd.log
if [ -z "$IdleWorkers" ];then     
echo "`date +%Y%m%d-%T` $hostip:$hostname: httpd is down and now start" >> var/log/httpd.log
status=1
remark="start"
/etc/init.d/httpd3 start
elif [ $BusyWorkers -gt 254 ];then  
        echo "`date +%Y%m%d-%T` $hostip:$hostname: httpd's proccess is ${arr[0]}" >> var/log/httpd.log
#        /etc/init.d/httpd status >> var/log/httpd.log
#        /etc/init.d/httpd stop 2>&1 >> var/log/httpd.log
#        /etc/init.d/httpd start 2>&1 >> var/log/httpd.log
		status=1
		remark="busy"
else
    echo "`date +%Y%m%d-%T` $hostip:$hostname: httpd is OK" >> var/log/httpd.log
fi
echo "{'server':'apache3','remark':$remark,'status':$status,'CpuLoad':$CpuLoad,'Uptime':$Uptime,'ReqPerSec':$ReqPerSec,'BytesPerSec':$BytesPerSec,'BytesPerReq':$BytesPerReq,'BusyWorkers':$BusyWorkers,'IdleWorkers':$IdleWorkers,'Scoreboard':$scoreboard,'date':$mydate}"

rm -f tmp/http*
rm -f var/run/httpd.pid
