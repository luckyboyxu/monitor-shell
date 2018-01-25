#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

########################################################################
# mo_nginx
# hostname active_conn accepts handled requests Reading Writing Waiting date
########################################################################

self_check $server_name
echo $$ > var/run/$server_name.pid

tmp_flag="tmp/mo_nginx_new.tmp"
if [ ! -f ${tmp_flag} ];then
    echo 0 > ${tmp_flag}
fi

if [ $# -eq 0 ];then
	port=80
else
	port=$1
fi

curl "http://127.0.0.1:${port}/nginx_status" > tmp/nginx.$$ 2> /dev/null

active_conn=`sed -n '1'p tmp/nginx.$$ | awk '{print $3}'`
server=`sed -n '3'p tmp/nginx.$$`
accepts=`echo $server | awk '{print $1}'` 
handled=`echo $server | awk '{print $2}'`
requests=`echo $server | awk '{print $3}'`
act=`sed -n '4'p tmp/nginx.$$`
Reading=`echo $act | awk '{print $2}'`
Writing=`echo $act | awk '{print $4}'`
Waiting=`echo $act | awk '{print $6}'`

nginx=`pgrep -lo nginx`
if [ ! -n "$nginx" ];then
    status=1

    /etc/init.d/nginx_new start > /dev/null 2>&1
    nginx=`pgrep -lo nginx`
    if [ ! -n "$nginx" ];then
        message="$mydate $hostname nginx is down and restart fail"
		status=3
    else
        message="$mydate $hostname nginx is down but restart ok"
    fi   
fi

if [ ! -f "/var/run/nginx/nginx.pid" ]; then  
    status=1
    ps -ef | grep 'nginx' | grep -v 'mo_nginx.sh' | grep -v 'grep' | while read line
	do
		kill -9 `echo $line |  awk '{print $2}'`   > /dev/null 2>&1
	done
    /etc/init.d/nginx_new start  > /dev/null 2>&1
    nginx=`pgrep -lo nginx`
    if [ ! -n "$nginx" ];then
        message="$mydate $hostname nginx pid is missing and restart nginx fail"
		status=3
    else
        restart_flag=`cat ${tmp_flag}`
        if [ $restart_flag -eq 1 ];then
            status=3
        else
            echo 1 > ${tmp_flag}
        fi
        message="$mydate $hostname nginx pid is missing but restart ok"
    fi
else
    echo 0 > ${tmp_flag}
fi

echo "{'hostname':'$hostname','status':'$status','active_conn':'$active_conn','accepts':'$accepts','handled':'$handled','requests':'$requests','Reading':'$Reading','Writing':'$Writing','Waiting':'$Waiting','msg':'$message','date':'$mydate'}"

rm -f tmp/nginx.*
rm -f var/run/$server_name.pid
