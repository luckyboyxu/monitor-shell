#! /bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. ./conf/globle.cfg
. ./bin/functions.sh

status=0
message="nothing"
########################################################################
# mo_ping.sh 
# hostname status message date other
########################################################################
server_ip=$1

server_name=${server_name}.${server_ip}

self_check $server_name
echo $$ > var/run/$server_name.pid

tmp_file=/tmp/route.txt
file=/tmp/route_to_$1.txt

if  [ ! -e $file ] ;then
    ping -c 2 -w 2 $server_ip > /dev/null
    if [ $? != 0 ];then
		status=1
		message="$server_ip is down"
		others="nothing"
		echo "{'hostname':'$hostname','status':'${status}','msg':'${message}','date':'$mydate','others':'$other'}"
    	exit 1
    else
    	route_tmp=`mtr -c 5 --report $1 > $tmp_file`
    	cat $tmp_file | sed '/HOST/d' | awk '{print $2}' > $file
    	rm -rf $tmp_file
    fi
fi

loss_max=3 #平均丢包率阙值为3%
avg_max=60 #平均延时阙值为60ms
ping_pac=10 #每次ping 10个包

ping -c 2 -w 2 $server_ip >/dev/null
#-----------------------------------------------------------------------------------------------
#若ping成功，则判断延时及丢包率
if [ $? = 0 ];then
	ping_mes=`ping -c $ping_pac $server_ip | tail -2`
	loss=`echo $ping_mes|awk -F',' '{print $3}'|awk -F' ' '{print $1}'`
	loss=${loss%?}
	avg=`echo $ping_mes|awk -F',' '{print $4}'|awk -F' ' '{print $6}'|awk -F'/' '{print $2}'`
	if [ $(echo "$loss > $loss_max"|bc) -eq 1 -o $(echo "$avg > $avg_max"|bc) -eq 1 ];then
		status=1
		message="loss:${loss}%; avg:${avg}ms"
	else
		others=";$server_ip loss:${loss}%; avg:${avg}ms"
		status=0
		message=";nothing"
	fi
#----------------------------------------------------------------------------------------------
#若ping不通则找出不通的节点，并测出所有ping通主机的平均丢包率及延时
else
	status=2
	#message="$server_ip's port:$server_port down"
	message=""
	ip_num=1
	ip_f=""
	others=""
	for ip in `tac $file|sed '1d'`
	do
		ping $ip -c2 >/dev/null
		if [ $? != 0 ];then
			ip_f=$ip
			#let ip_num++
		else
			ping_mes=`ping -c $ping_pac $ip | tail -2`
			loss=`echo $ping_mes|awk -F',' '{print $3}'|awk -F' ' '{print $1}'`
			loss=${loss%?}
			avg=`echo $ping_mes|awk -F',' '{print $4}'|awk -F' ' '{print $6}'|awk -F'/' '{print $2}'`
			if [ $(echo "$loss > $loss_max"|bc) -eq 1 -o $(echo "$avg > $avg_max"|bc) -eq 1 ];then
				message="$message;${ip} loss:${loss}% avg:${avg}ms"
			else
				others="$others;${ip} loss:${loss}% avg:${avg}ms"
			fi
		fi
	done
	if [ "$ip_f" = "" ];then
			message_t="${server_ip} is down" 
	else
			message_t="${ip_f} is down"
	fi
	message="${message_t}${message}"
fi
if [ "$others" = "" ];then
	others=";nothing"
fi
echo "{'hostname':'$hostname','status':'$status','msg':'${message}','date':'$mydate','others':'${others:1}'}"	
