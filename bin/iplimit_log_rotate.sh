#!/bin/bash
##################################################################
# get iplimit_log from passport_group to log_center
# 2013/03/14
# author:chiy
##################################################################

. functions.sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

mypath=/root/crontab
mylog=/root/crontab/var/log
iplimit_log_path=/var/log/500wan
ip=`ifconfig | grep -1 "eth0" | grep "inet addr" | awk -F: '{split($2,d2," ");print d2[1]}'`
today=`date +%Y_%m_%d`
yestoday=`date -d "1 day ago" +%Y%m%d`
iplimit_log_bak=/data/log_bak/$yestoday/iplimit_log

[ ! -e $mylog ] && mkdir -p $mylog
echo >> $mylog/iplimit_log_rotate.log
echo >> $mylog/iplimit_log_rotate.log
echo "######### $today #########" >> $mylog/iplimit_log_rotate.log
echo "iplimit_log_rotate start:" >> $mylog/iplimit_log_rotate.log

########   gzip
find $iplimit_log_path -type f | grep "$iplimit_log_path/ipuserlimit_errorlogin_" | grep -v "$today" | sort > $mypath/tmp/gzip_iplimit_log.list
echo 'gzip:' >> $mylog/iplimit_log_rotate.log

while read logname
do
    gzip $logname
    echo "    $logname" >> $mylog/iplimit_log_rotate.log
done < $mypath/tmp/gzip_iplimit_log.list


#########  mv 
ls $iplimit_log_path | grep "^ipuserlimit_errorlogin_.*.gz$" | grep -v "$today" > $mypath/tmp/mv_iplimit_log.list
echo 'mv:' >> $mylog/iplimit_log_rotate.log

while read logname
do
    logday=`echo $logname | awk -F\_ '{print $3$4$5}' | cut -c1-8`
    [ ! -e $iplimit_log_bak/$logday/iplimit_log ] && mkdir -p $iplimit_log_bak/$logday/iplimit_log
    mv $iplimit_log_path/$logname $iplimit_log_path/"$ip"_$logname
    mv $iplimit_log_path/"$ip"_$logname $iplimit_log_bak
    echo "    $logname" >> $mylog/iplimit_log_rotate.log
done < $mypath/tmp/mv_iplimit_log.list

#########  getlog_msg
flag=`wc -l $mypath/tmp/mv_iplimit_log.list|awk '{print $1}'`
if [ $flag -gt 0 ];then
    rsync_mod="$ip::log_bak"
    src_path="$yestoday/iplimit_log"
    dest_path="$yestoday/"

    direct=serlog
    values="$rsync_mod,$src_path,$dest_path"

    echo "chown -R www.www /data/log_bak" >> $mylog/iplimit_log_rotate.log
    chown -R www.www /data/log_bak
    echo "mq_getlog_msg $direct $values" >> $mylog/iplimit_log_rotate.log
    mq_getlog_msg $direct $values
fi