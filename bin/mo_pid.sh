#!/bin/sh
#######检查各个进程的pid文件是否存在
. conf/globle.cfg
. bin/functions.sh
######定义变量
processpid='/usr/local/apache1/logs/httpd.pid|/usr/local/apache2/logs/httpd.pid|/usr/local/apache3/logs/httpd.pid'
processname='/usr/local/apache1/bin/httpd1|/usr/local/apache2/bin/httpd2|/usr/local/apache3/bin/httpd3'


#####定义检测函数


n=`echo "$processpid" |awk -F '|' '{print NF}'`
for ((i=1;i<=n;i++))
do
	pidfile=`echo $processpid |awk -v i=$i  -F '|' '{print $i}'`
	pname=`echo $processname |awk -v i=$i  -F '|' '{print $i}'`
	pid=`ps -ef |grep "$pname" |grep root |grep -v grep |awk '{print $2}'`
	fpid=`cat $pidfile`
	prog=`echo $pname |sed 's/.*\/\(.*\)/\1/g'`
	if [ -e "$pidfile" ] ;then 
	 
		if [ "$pid" != "$fpid" ] ;then 
		message="$hostip : $hostname the pidfile of $prog is not exist" 
		sendmsg "$message" "$Phone_list" "$prog"
		else
		echo "`date +%F-%T` $hostip: $hostname pidfile of $prog is normal" >> var/log/pid.log
		fi
	else 
		message="$hostip : $hostname the pidfile of $prog is not exist" 
		sendmsg "$message" "$Phone_list" "$prog" 
		echo "`date +%F-%T` $hostip: $hostname pidfile of $prog is not exist" >> var/log/pid.log
	fi
done


