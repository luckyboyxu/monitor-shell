#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath
echo $MyPath
. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

#####################################################################
# http进程监控 
#####################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

php_status=`curl http://127.0.0.1/ping`
if [ "$php_status" != "pong" ];then     
    status=1
    /etc/init.d/php-fpm start >/dev/null 2>&1
    php_status=`curl http://127.0.0.1/ping`
    if [ "$php_status" != "pong" ];then
        message="$mydate $hostname php-fpm is down and restart fail"
		status=3
    else
        message="$mydate $hostname php-fpm is down but restart ok"
    fi
fi

curl http://127.0.0.1/status > tmp/php-fpm.$$ 2> /dev/null

conn=`sed -n '/conn/'p tmp/php-fpm.$$ |  awk -F\: '{print $2}'|sed s'/ //'g`
pool=`sed -n '/pool/'p tmp/php-fpm.$$ |  awk -F\: '{print $2}'|sed s'/ //'g`
manager=`sed -n '/manager/'p tmp/php-fpm.$$ |  awk -F\: '{print $2}'|sed s'/ //'g`
idle=`sed -n '/idle/'p tmp/php-fpm.$$ |  awk -F\: '{print $2}'|sed s'/ //'g`
active=`sed -n '/active/'p tmp/php-fpm.$$ |  awk -F\: '{print $2}'|sed s'/ //'g`
total=`sed -n '/total/'p tmp/php-fpm.$$ |  awk -F\: '{print $2}'|sed s'/ //'g`


if [ $active -gt 250 ];then  
     status=3
     message="$mydate $hostname php-fpm active process is $active"
fi

echo "{'hostname':'$hostname','status':'$status','accepted_conn':'$conn','pool':'$pool','process_manager':'$manager','idle_process':'$idle','active_process':'$active','total_process':'$total','msg':'$message','date':'$mydate'}"

rm -f tmp/php-fpm*
rm -f var/run/$server_name.pid
