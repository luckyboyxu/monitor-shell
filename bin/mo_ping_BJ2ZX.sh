#! /bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. ./conf/globle.cfg
. ./bin/functions.sh

status=0
message="nothing"
########################################################################
# 北京对中心网络监控
# mo_ping_BJ2ZX.sh 
# hostname status message date other
########################################################################
server_ip=$1
server_port=$2

case $server_ip in
"172.18.16.28")
	area="AS主链路"
	;;
"172.18.16.30")
	area="AS备链路"
	;;
"18.1.5.2")
	area="IHS主链路"
	;;
"18.1.5.3")
	area="IHS备链路"
	;;
"18.1.9.5")
	area="IHS主光纤"
	;;
"18.1.9.1")
	area="IHS备光纤"
	;;
*)
	area="未知链路"
	;;
esac

server_name=${server_name}.${server_ip}.${server_port}

self_check $server_name
echo $$ > var/run/$server_name.pid

#log="./var/log/message"
#log_dir=`dirname $log`
#if [ ! -e $log_dir ];then
#	mkdir -p $log_dir
#fi
#if [ ! -e $log ];then
#	touch $log
#fi

tmp_file=/tmp/route.txt
file=/tmp/route_to_$1.txt

if  [ ! -e $file ] ;then
    ping -c 2 -w 2 $server_ip > /dev/null
    if [ $? != 0 ];then
	status=1
	message="$area:ping loss 100%"
	others="nothing"
	echo "{'hostname':'$hostname','status':'${status}','loss':100,'avg':'null','msg':'${message}','date':'$mydate','others':'$other'}"
    	exit 1
    else
    	route_tmp=`mtr -c 5 --report $1 > $tmp_file`
    	cat $tmp_file | sed '/HOST/d' | awk '{print $2}' > $file
    	rm -rf $tmp_file
    fi
fi


loss_max=3
avg_max=100
ping_pac=10

ping_mes=`ping -c $ping_pac $server_ip | tail -2`
loss=`echo $ping_mes|awk -F',' '{print $3}'|awk -F' ' '{print $1}'`
loss=${loss%?}
avg=`echo $ping_mes|awk -F',' '{print $4}'|awk -F' ' '{print $6}'|awk -F'/' '{print $2}'`
result_loss=$loss
result_avg=$avg
#echo "${mydate} ${server_ip} loss:${loss}% avg:${avg}ms" >> $log
if [ $(echo "$loss > $loss_max"|bc) -eq 1 -o $(echo "$avg > $avg_max"|bc) -eq 1 ];then
	status=1
	message="$area loss:${loss}%;avg:${avg}ms"
else
	#echo "loss:${loss}%; avg:${avg}ms"
	others=";$server_ip loss:${loss}%;avg:${avg}ms"
	status=0
	message="nothing"
fi
if [ "$server_port" != "" ];then
	nc -n -w1 $server_ip $server_port >/dev/null
	if [ $? != 0 ];then
	#----------------------------------------------------------------------------------------------
	#若nc不通则找出不通的节点，并测出所有ping通主机的平均丢包率及延时
		status=3
		message="$area:$server_ip's port:$server_port down"

		ip_num=1
		ip_f=""
		others=""
		for ip in `tac $file`
		do
			ping $ip -c2 >/dev/null
			if [ $? != 0 ];then
				ip_f=$ip
				let ip_num++
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
				message_t="$area:$server_ip's port:$server_port down;${server_ip} is accessed"   
		else
				message_t="$area:$ip_f is down"
		fi
		message="${message_t}${message}"
	fi
fi
if [ "$others" = "" ];then
	others="nothing"
fi
echo "{'hostname':'$hostname','status':'$status','loss':'$result_loss','avg':'$result_avg','msg':'${message}','date':'$mydate','others':'${others:1}'}"	
