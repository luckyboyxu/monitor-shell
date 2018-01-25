#!/bin/sh
mydate=`date "+%Y-%m-%d %H:%M:%S"`
status=0
warning=500485760
interface=$1

in_old=`cat /proc/net/dev | awk '/'"$interface"'/ {print $1}' | cut -d":" -f2`
out_old=`cat /proc/net/dev | awk '/'"$interface"'/ {print $9}'`

sleep 1

in_new=`cat /proc/net/dev | awk '/'"$interface"'/ {print $1}' | cut -d":" -f2`
out_new=`cat /proc/net/dev | awk '/'"$interface"'/ {print $9}'`
error=`cat /proc/net/dev | awk '/'"$interface"'/ {print $3}'`

let "in=($in_new-$in_old)*8"
let "out=($out_new-$out_old)*8"



if [ "$out" -gt "$warning" ];then
  status=1
fi

echo "{'interface':'$interface','RX_in':'$in','RX_out':'$out','error':'$error','status':'$status','date':'$mydate'}"
