#!/bin/sh

MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
result=""

########################################################################
# mo_redis
# hostname ip port connect memory hits get_ps set_ps status msg date
########################################################################

realip=$hostip
out=""
while read ip_port
do
	if [[ "$ip_port" =~ $realip ]];then
        hostip=$(echo $ip_port  | awk '{print $2}')
        port=$(echo $ip_port  | awk '{print $3}')

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

		result=`/usr/bin/python26 /root/crontab/bin/check_redis.py $hostname $hostip $port  $max_mem $maxclients`
		out="$out,$result"
		rm -f var/run/$server_name.pid
	fi
done < conf/redis.cfg
if [ "$result" == "" ];then
	echo "[{'date':'$mydate','ip':'$hostip:0','hostname':'$hostname','msg':'no thing','port':'0','status':'$status','uptime_in_seconds':'','keyspace_hits':'','keyspace_misses':'','hits_rate':'','connected_clients':'','used_memory':''}]"
else
	echo "[${out:1}]"
fi