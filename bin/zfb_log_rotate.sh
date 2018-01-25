#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

mypath=/root/crontab
mylog=/root/crontab/var/log
zfb_log_path=/var/log/500wan
ip=`ifconfig | grep -1 "eth0" | grep "inet addr" | awk -F: '{split($2,d2," ");print d2[1]}'`
today=`date +%Y%m%d`
zfb_log_bak=/var/log/zfb_log_bak

[ ! -e $mylog ] && mkdir -p $mylog
[ ! -e $zfb_log_bak ] && mkdir -p $zfb_log_bak
echo >> $mylog/zfb_log_rotate.log
echo >> $mylog/zfb_log_rotate.log
echo "######### $today #########" >> $mylog/zfb_log_rotate.log
echo "zfb_log_rotate start:" >> $mylog/zfb_log_rotate.log

########   gzip
find $zfb_log_path -type f | grep "$zfb_log_path/finance_zfbbatch_auto_[0-9]\{8\}.log$" | grep -v "$today" | sort > $mypath/tmp/gzip_zfb_log.list
echo 'gzip:' >> $mylog/zfb_log_rotate.log

while read logname
do
    gzip $logname
    echo "    $logname" >> $mylog/zfb_log_rotate.log
done < $mypath/tmp/gzip_zfb_log.list


#########  mv 
ls $zfb_log_path | grep "finance_zfbbatch_auto_[0-9]\{8\}.log.gz$" | grep -v "$today" > $mypath/tmp/mv_zfb_log.list
echo 'mv:' >> $mylog/zfb_log_rotate.log

while read logname
do 
    logday=`echo $logname | cut -c 23-30`
    [ ! -e $zfb_log_bak/$logday/zfb_log ] && mkdir -p $zfb_log_bak/$logday/zfb_log
    mv $zfb_log_path/$logname $zfb_log_path/"$ip"_$logname
    mv $zfb_log_path/"$ip"_$logname $zfb_log_bak/$logday/zfb_log
    echo "    $logname" >> $mylog/zfb_log_rotate.log
done < $mypath/tmp/mv_zfb_log.list


#########  rsync
ls $zfb_log_bak > $mypath/tmp/rsync_zfb_log.list
echo 'rsync:' >> $mylog/zfb_log_rotate.log

while read filename
do
    rsync -az $zfb_log_bak/$filename 192.168.0.124::data_logbak
    echo "    $filename" >> $mylog/zfb_log_rotate.log
done < $mypath/tmp/rsync_zfb_log.list

############ delete old log
ls $zfb_log_bak > $mypath/tmp/delete_zfb_log.list
echo 'delete:' >> $mylog/zfb_log_rotate.log 

while read logname
do
    if [ $logname -le `date -d "7 days ago" +%Y%m%d` ];then
        rm -rf $zfb_log_bak/$logname
	echo "    $logname" >> $mylog/zfb_log_rotate.log
    fi
done < $mypath/tmp/delete_zfb_log.list




#########  old log bak    
rsync -azv /data/web_static/static/public/admin 192.168.0.124::data_logbak/zfb_data/$ip/ >> $mylog/zfb_data_rotate.log
rsync -azv /data/web_static/static/admin/finance/log 192.168.0.124::data_logbak/zfb_data/$ip/ >> $mylog/zfb_data_rotate.log