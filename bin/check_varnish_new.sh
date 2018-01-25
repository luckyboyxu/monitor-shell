#!/bin/sh
MyPath=$(cd $(dirname $0)/..;pwd)
cd $MyPath
. conf/globle.cfg
. bin/functions.sh

status=0

##########################################################
#check_varnish
#hostname msg date
##########################################################

self_check $server_name
echo $$ > var/run/$server_name.pid
out=$(curl -I -m 10  -H"host:static.500.com"  http://127.0.0.1/static/varnishtest -o /dev/null -s -w %{http_code})
if [ $out != 200 ];then
	num=`ps -ef | grep varnish | grep -v grep | grep -v check`
	if [ $? -gt 0 ];then
		status=1
		varnishd -f /etc/varnish/default.vcl -u varnish -g varnish -s malloc,50G -T 127.0.0.1:2000 -a 0.0.0.0:80 > /dev/null 2>&1
		if [ $? -eq 0 ];then
			error="varnish is down, restart ok !"
		else
			error="varnish is down, restart failed ! please pay attention !!"
		fi
		echo "{'hostname':'$hostname','msg':'$error','status':$status,'date':'$mydate'}"

	else
		pid=`ps -ef | grep varnish | grep -v grep | grep -v check | grep root | awk '{print $2}'`
		`kill -9 $num`
		if [ $? = 0 ];then
			varnishd -f /etc/varnish/default.vcl -u varnish -g varnish -s malloc,50G -T 127.0.0.1:2000 -a 0.0.0.0:80 > /dev/null 2>&1
			if [ $? = 0 ];then
				error="varnish is down, restart ok !"
			else
				error="varnish is down, restart failed ! please pay attention !!"
			fi
			echo "{'hostname':'$hostname','msg':'$error','status':$status,'date':'$mydate'}"
		fi
	fi
else	
	error="nothing"
	echo "{'hostname':'$hostname','msg':'$error','status':$status,'date':'$mydate'}"
fi
rm -f var/run/$server_name.pid
