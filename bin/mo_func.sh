#!/bin/sh

. conf/globle.cfg
. bin/functions.sh

########################################################################
# func?à??
########################################################################
self_check func
echo $$ > var/run/func.pid


echo -n "$time " >> var/log/func.log
func=`pgrep -lo func`
if [ ! -n "$func" ];then
  message="$hostip:$hostname: :func is down"
  sendmsg "$message" "$Phone_list" "$prog"
  echo "`date +%Y%m%d-%X` $hostip:$hostname: func is down" >> var/log/func.log
else
  echo "`date +%Y%m%d-%X` $hostip:$hostname: func is OK" >> var/log/func.log
fi

rm -f tmp/func.tmp.*
rm -f var/run/func.pid
