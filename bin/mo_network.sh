#!/bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

########################################################################
# mo_network
# hostname ip dev mac RX TX packet_TX packet_RX msg status date
########################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

#进流量阙值为$1，出流量阙值为$2，默认均为600Mb/s
if [ $# != 2 ];then
	in_alert=600
	out_alert=600
else
	in_alert=$1
	out_alert=$2
fi

sleep_time=60
network_pre="./tmp/network_pre.txt"
network_nex="./tmp/network_nex.txt"
cat /proc/net/dev > ${network_pre}
sleep ${sleep_time}
cat /proc/net/dev > ${network_nex}

result=""

for eth in `route -n|sed '1,2d'|awk '{print $NF}'|sort -u|uniq|sed /lo/d`
do
	status=0
	msg="noting"
	mydate=$(date "+%Y-%m-%d %T")
	mac=`ifconfig ${eth}|grep HWaddr|awk '{print $NF}'`	
	ip=`ifconfig ${eth}|grep 'inet addr:'|tr : ' '|awk '{print $3}'`
	tmp=$(cat ${network_pre} | grep $eth | tr : " ")
	RXpre=$(echo $tmp | awk '{print $2}')
	TXpre=$(echo $tmp | awk '{print $10}')
	P_R=$(echo $tmp | awk '{print $3}')
	E_R=$(echo $tmp | awk '{print $4}')
	D_R=$(echo $tmp | awk '{print $5}')
	P_T=$(echo $tmp | awk '{print $11}')
	E_T=$(echo $tmp | awk '{print $12}')
	D_T=$(echo $tmp | awk '{print $13}')
	let Packet_RX_pre=P_R+E_R+D_R
	let Packet_TX_pre=P_T+E_T+D_T
	
	tmp=$(cat ${network_nex} | grep $eth | tr : " ")
	RXnext=$(echo $tmp | awk '{print $2}')
	TXnext=$(echo $tmp | awk '{print $10}')
	P_R=$(echo $tmp | awk '{print $3}')
	E_R=$(echo $tmp | awk '{print $4}')
	D_R=$(echo $tmp | awk '{print $5}')
	P_T=$(echo $tmp | awk '{print $11}')
	E_T=$(echo $tmp | awk '{print $12}')
	D_T=$(echo $tmp | awk '{print $13}')
	let Packet_RX_next=P_R+E_R+D_R
	let Packet_TX_next=P_T+E_T+D_T

	let RX=(RXnext-RXpre)*8/sleep_time
	let TX=(TXnext-TXpre)*8/sleep_time
	let Packet_RX=(Packet_RX_next-Packet_RX_pre)/sleep_time
	let Packet_TX=(Packet_TX_next-Packet_TX_pre)/sleep_time
	
	let R=RX/1000000
	let T=TX/1000000
	let R_T=R+T

	if [ ${R} -ge ${in_alert} -o ${T} -ge ${out_alert}  ];then
		status=3
		msg="${hostname} in ${R}Mb/s,out ${T}Mb/s,total flow is ${R_T}Mb/s"
	fi
	result="$result,{'hostname':'$hostname','ip':'${ip}','status':'${status}','dev':'${eth}','mac':'${mac}','RX':'${RX}','TX':'${TX}','packet_RX':'${Packet_RX}','packet_TX':'${Packet_TX}','msg':'${msg}','date':'$mydate'}"	
done
echo "[${result:1}]"
rm -f ${network_pre}
rm -f ${network_nex}
rm -f var/run/$server_name.pid
