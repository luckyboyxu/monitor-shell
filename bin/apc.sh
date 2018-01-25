#!/bin/sh

start_time=`curl 'http://127.0.0.1:8080/apc.php?act=start_time'`
start_time=`date -d @"$start_time" +%T`
mkdir -p var/log/apc
rm tmp/filelist.list
curl 'http://127.0.0.1:8080/apc.php?act=apc' > tmp/apc_cache.list
cp tmp/apc_cache.list var/log/apc/`date +%Y%m%d-%H%M`-apc.log

for logfile in `ls -S /var/log/nginx/ | head -n 5`
do
    domain=`head -n 1 /var/log/nginx/$logfile | awk -F"\"" '{print$(NF-1)}'`
    realdomain=`awk '{if($1=='\"$domain\"') print $2}' conf/apc_domain.list`

    [ -z $realdomain ] && realdomain=$domain

    sed -n "/$start_time/,/^$/p" /var/log/nginx/$logfile | awk -F"[ ?]" '{if($7~".php") print "'$realdomain'"$7}' | sort | uniq -c | sort -rn | head -n 5 >> tmp/filelist.list
done


while read number pageurl
do
    hits=`grep $pageurl tmp/apc_cache.list | awk '{print $2}'`
    [ -z $hits ] && hits=0
    echo `date +%Y%m%d-%H` $pageurl $hits $number $(( $hits*100/$number  ))"%" >> var/log/apc.log
done<tmp/filelist.list
