#!/bin/sh

MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0

########################################################################
# mo_redis
# hostname ip port connect memory hits get_ps set_ps status msg date
########################################################################

if [ "$#" -ne 2 ];then
    echo "paras error"
    rm -f var/run/$server_name.pid
    exit -1
fi

hostip=$1
port=$2

server_name=$server_name.$hostip.$port

self_check $server_name
echo $$ > var/run/$server_name.pid

maxmemory=`awk '{if($1=="maxmemory")print $2}' /etc/redis/$port.conf`
maxclients=`awk '{if($1=="maxclients")print $2}' /etc/redis/$port.conf`
ret_m=`echo $maxmemory | grep 'm'`
num=`echo $maxmemory | sed 's/[^0-9]//g'`
if [ ! -n "$ret_m" ];then
	let "max_mem=$num*1024*1024*1024"
else
	let "max_mem=$num*1024*1024"
fi

/usr/bin/python26 /root/crontab/bin/check_redis.py $hostname $hostip $port  $max_mem $maxclients

rm -f var/run/$server_name.pid
