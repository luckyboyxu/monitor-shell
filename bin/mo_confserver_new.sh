#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

mydate=`date "+%Y-%m-%d %H:%M:%S"`

status=0

. conf/globle.cfg
. bin/functions.sh

########################################################################
# confserver 配置中心服务端连接监控
########################################################################

#self_check confserver
#echo $$ > var/run/confserver.pid
self_check $server_name
echo $$ > var/run/$server_name.pid

check_2000=`netstat -anp | grep "$hostip:2000" | grep LISTEN`
if [ -z "$check_2000" ];then
   status=1
   remark="check_2000 fail"
else
   msg_2000=`netstat -anp | grep "$hostip:2000" | grep -v LISTEN | awk '{print $6}' | sort | uniq -c | awk 'BEGIN{ORS=""}{print $0}' | sed 's/  */ /g'`
   remark="check_2000 ok"
fi

check_5000=`netstat -anp | grep "$hostip:5000" | grep LISTEN`
if [ -z "$check_5000" ];then
   status=1
   remark="$remark;check_5000 fail"
else
   msg_5000=`netstat -anp | grep "$hostip:5000" | grep -v LISTEN | awk '{print $6}' | sort | uniq -c | awk 'BEGIN{ORS=""}{print $0}' | sed 's/  */ /g'`
   remark="$remark;check_5000 ok"
fi

echo "{'hostname':'$hostname','date':'$mydate','status':'$status','msg':'$remark','con_2000':'$msg_2000','con_5000':'$msg_5000'}"

rm -f tmp/confserver.tmp.*
rm -f var/run/$server_name.pid
