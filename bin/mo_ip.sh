#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath
h=`date +%H`
m=`date +%M`
let "now=$h*60+$m"
deadline=1000

> $MyPath/tmp/ip_blacklist
while read line
do
        url=`echo $line | awk '{print $1}'`
        site=`echo $line | awk '{print $2}'`
        logfile=`awk '{if($1=="'$site'")print $2}'  $MyPath/conf/log.list`
        > $MyPath/tmp/$site.log
        tac $logfile | awk -F':' -vnow=$now '{tim=$2*60+$3;pass=now-tim;print $0;if((now-tim)>10){exit}}' >> $MyPath/tmp/$site.log
        grep "$url"     $MyPath/tmp/$site.log | awk '{print $1}' | sort | uniq -c | sort -nr | awk -vdeadline=$deadline '{if($1>deadline)print $2}' >> $MyPath/tmp/ip_blacklist
done < $MyPath/conf/url.list
