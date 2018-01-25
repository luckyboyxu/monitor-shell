#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

mypath=/root/crontab
mylog=/root/crontab/var/log
x500wan_log_path=/var/log/500wan
ip=`ifconfig | grep -1 "eth0  " | grep "inet addr" | awk -F: '{split($2,d2," ");print d2[1]}'`
today=`date +%Y%m%d`
x500wan_log_bak=/var/log/x500wan_log_bak

[ ! -e $mylog ] && mkdir -p $mylog
echo >> $mylog/x500wan_log_rotate.log
echo >> $mylog/x500wan_log_rotate.log
echo "######### $today #########" >> $mylog/x500wan_log_rotate.log
echo "x500wan_log_rotate start:" >> $mylog/x500wan_log_rotate.log

#########  mv 
find $x500wan_log_path -type f -mtime +7 | grep -E "log$|log.[0-9]*$" | sed 's/\/var\/log\/500wan\///g' > $mypath/tmp/mv_x500wan_log.list
cat $mypath/tmp/mv_x500wan_log.list | grep "/" | sed 's/\/.*log//g' | sort -u > $mypath/tmp/mv_x500wan_dir.list
echo 'mv:' >> $mylog/x500wan_log_rotate.log

[ ! -e $x500wan_log_bak/$today/x500wan_log_bak ] && mkdir -p $x500wan_log_bak/$today/x500wan_log_bak

while read dirname
do
    [ ! -e $x500wan_log_bak/$today/x500wan_log_bak/$dirname ] && mkdir -p $x500wan_log_bak/$today/x500wan_log_bak/$dirname
done <  $mypath/tmp/mv_x500wan_dir.list

while read logname
do
    mv $x500wan_log_path/$logname $x500wan_log_bak/$today/x500wan_log_bak/$logname
    echo "    $logname" >> $mylog/x500wan_log_rotate.log
done < $mypath/tmp/mv_x500wan_log.list

#########  tar & gzip
echo 'tar & gzip:' >> $mylog/x500wan_log_rotate.log
cd $x500wan_log_bak/$today/x500wan_log_bak
tar -czf "$ip"_x500wan_log.tar.gz *
find ./ | grep -v "tar.gz" | grep -v "/$" | xargs rm -rf 
cd $mypath/bin
echo '    OK!' >> $mylog/x500wan_log_rotate.log

#########  rsync
ls $x500wan_log_bak > $mypath/tmp/rsync_x500wan_log.list
echo 'rsync:' >> $mylog/x500wan_log_rotate.log

while read filename
do
    rsync -az $x500wan_log_bak/$filename 192.168.0.124::data_logbak
    [ $! -ne 0 ] && echo "  Error!" && exit -1
    echo "    $filename" >> $mylog/x500wan_log_rotate.log
done < $mypath/tmp/rsync_x500wan_log.list

############ delete old log
ls $x500wan_log_bak > $mypath/tmp/delete_x500wan_log.list
echo 'delete:' >> $mylog/x500wan_log_rotate.log

while read logname
do
    rm -rf $x500wan_log_bak/$logname
    echo "    $logname" >> $mylog/x500wan_log_rotate.log
done < $mypath/tmp/delete_x500wan_log.list
