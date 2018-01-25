#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

mypath=/root/crontab
mylog=/root/crontab/var/log
syslog_path=/var/log
ip=`ifconfig | grep -1 "eth0" | grep "inet addr" | awk -F: '{split($2,d2," ");print d2[1]}'`
today=`date +%Y%m%d`
syslog_bak=/var/log/syslog_bak

[ ! -e $mylog ] && mkdir -p $mylog
[ ! -e $syslog_bak ] && mkdir -p $syslog_bak
echo >> $mylog/syslog_rotate.log
echo >> $mylog/syslog_rotate.log
echo "######### $today #########" >> $mylog/syslog_rotate.log
echo "syslog_rotate start:" >> $mylog/syslog_rotate.log

########   gzip
find $syslog_path -type f | grep "$syslog_path/messages.[0-9]$" | sort > $mypath/tmp/gzip_syslog.list
echo 'gzip:' >> $mylog/syslog_rotate.log

while read logname
do
    gzip $logname
    echo "    $logname" >> $mylog/syslog_rotate.log
done < $mypath/tmp/gzip_syslog.list


#########  mv 
ls $syslog_path | grep "messages.[0-9].gz$" > $mypath/tmp/mv_syslog.list
echo 'mv:' >> $mylog/syslog_rotate.log

while read logname
do 
    logday=`date +%Y%m%d`
    [ ! -e $syslog_bak/$logday/syslog ] && mkdir -p $syslog_bak/$logday/syslog
    mv $syslog_path/$logname $syslog_path/"$ip"_$logname
    mv $syslog_path/"$ip"_$logname $syslog_bak/$logday/syslog
    echo "    $logname" >> $mylog/syslog_rotate.log
done < $mypath/tmp/mv_syslog.list


#########  rsync
ls $syslog_bak > $mypath/tmp/rsync_syslog.list
echo 'rsync:' >> $mylog/syslog_rotate.log

while read filename
do
    rsync -az $syslog_bak/$filename 192.168.0.124::data_logbak
    echo "    $filename" >> $mylog/syslog_rotate.log
done < $mypath/tmp/rsync_syslog.list

############ delete old log
ls $syslog_bak > $mypath/tmp/delete_syslog.list
echo 'delete:' >> $mylog/syslog_rotate.log 

while read logname
do
    if [ $logname -le `date -d "7 days ago" +%Y%m%d` ];then
        rm -rf $syslog_bak/$logname
	echo "    $logname" >> $mylog/syslog_rotate.log
    fi
done < $mypath/tmp/delete_syslog.list
