#!/bin/sh

. conf/globle.cfg
. bin/functions.sh

echo "`date `:$hostip:$hostname:strace is starting...... " >> var/log/strace.log
for n in 0 1 2 3 
do 
	if [ $n -ne 0 ];then
		pro="/usr/local/apache$n/bin/httpd$n"
	else 
		pro="/usr/sbin/httpd"

	fi
	process=`echo $pro | sed 's/.*\/\(.*\)/\1/g'`
	name=$process.stc
	ps -ef |grep strace |grep $name
	if [ $? -eq 0 ];then
		ptime=`ps -ef |grep strace |grep $name |grep -v {} |awk '{print $5}' |xargs date +%s -d `
		time=`date +%s`
		tmptime=$(expr $time - $ptime)
		tmptime=$(bc <<< ${tmptime}/3600)
		if [ $tmptime == 1 ];then
		ps -ef |grep strace |grep $name |awk '{print $2}'|xargs kill -9 
			mv var/log/$name var/log/strace/$(date +%Y%m%d%H%M%S).$name
			pgrep -n "$process"|xargs -I {} strace -p {} -tt -T -s 1024 -o var/log/$name &

		else 
			continue
		fi
	else 
		mv var/log/$name var/log/strace/$(date +%Y%m%d%H%M%S).$name
		pgrep -n -x  "$process"|xargs -I {} strace -p {} -tt -T -s 1024 -o var/log/$name &
	fi

done
echo "`date`:$hostip:$hostname:strace is ending...... " >> var/log/strace.log
find /root/crontab/var/log/strace/ -mtime 7 -type f |xargs -I {} rm -f {}
find /root/crontab/var/log/strace/ -mtime 1 -type f |xargs -I {} gzip {}