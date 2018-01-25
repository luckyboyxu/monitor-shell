#!/bin/bash
##################################################################
# get charge_log from passport_group to log_center
# 2013/03/14
# author:chiy
##################################################################

. functions.sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

mypath=/root/crontab
mylog=/root/crontab/var/log
charge_log_path=/var/log/500wan
ip=`ifconfig | grep -1 "eth0" | grep "inet addr" | awk -F: '{split($2,d2," ");print d2[1]}'`
today=`date +%Y%m%d`
yestoday=`date -d "1 day ago" +%Y%m%d`
charge_log_bak=/data/log_bak/$yestoday/charge_log

[ ! -e $mylog ] && mkdir -p $mylog
echo >> $mylog/charge_log_rotate.log
echo >> $mylog/charge_log_rotate.log
echo "######### $today #########" >> $mylog/charge_log_rotate.log
echo "charge_log_rotate start:" >> $mylog/charge_log_rotate.log

########   gzip
find $charge_log_path -type f | grep "$charge_log_path/[0-9]\{8\}.log$" | grep -v "$today" | sort > $mypath/tmp/gzip_charge_log.list
echo 'gzip:' >> $mylog/charge_log_rotate.log

while read logname
do
    gzip $logname
    echo "    $logname" >> $mylog/charge_log_rotate.log
done < $mypath/tmp/gzip_charge_log.list


#########  mv 
ls $charge_log_path | grep "^[0-9]\{8\}.log.gz$" | grep -v "$today" > $mypath/tmp/mv_charge_log.list
echo 'mv:' >> $mylog/charge_log_rotate.log

while read logname
do
    [ ! -e $charge_log_bak ] && mkdir -p $charge_log_bak
    logday=`echo $logname | cut -c 1-8`
    mv $charge_log_path/$logname $charge_log_path/"$ip"_$logname
    mv $charge_log_path/"$ip"_$logname $charge_log_bak
    echo "    $logname" >> $mylog/charge_log_rotate.log
done < $mypath/tmp/mv_charge_log.list


#########  getlog_msg
flag=`wc -l $mypath/tmp/mv_charge_log.list|awk '{print $1}'`
if [ $flag -gt 0 ];then
    rsync_mod="$ip::log_bak"
    src_path="$yestoday/charge_log"
    dest_path="$yestoday/"

    direct=serlog
    values="$rsync_mod,$src_path,$dest_path"

    echo "chown -R www.www /data/log_bak" >> $mylog/charge_log_rotate.log
    chown -R www.www /data/log_bak
    echo "mq_getlog_msg $direct $values" >> $mylog/charge_log_rotate.log
    mq_getlog_msg $direct $values
fi