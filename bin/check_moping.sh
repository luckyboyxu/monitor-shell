#! /bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
msg="nothing"
########################################################################
# check_moping.sh
# hostname date msg
########################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

status=0
msg="nothing"
ps_num=`ps -ef|grep mo_ping|grep -v grep|wc -l`
if [ $ps_num -eq 0 ];then
	status=1
	sh /home/network_ping/mo_ping.sh $1 $2 $3
	ps_num=`ps -ef|grep mo_ping|grep -v grep|wc -l`
	if [ $ps_num -eq 0 ];then
		msg="$mydate $hostname mo_ping.sh is down and restart failed!"
	else
		msg="$mydate $hostname mo_ping.sh is donw but restart succeed!"
	fi
fi
echo "{'hostname':'$hostname','status':'$status','msg':'$msg','date':'$mydate'}"
rm -f var/run/$server_name.pid


