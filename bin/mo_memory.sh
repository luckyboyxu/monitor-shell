#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

mydate=`date "+%Y-%m-%d %H:%M:%S"`
status=0
message="no message"

########################################################################
# mo_memory
# hostname mem_swap mem_free mem_buff mem_cache swap_si swap_so date
########################################################################

self_check $server_name
echo $$ > var/run/$server_name.pid

msg=`vmstat | tail -n 1`
arr=($msg)

mem_swap="${arr[2]}"
mem_free="${arr[3]}"
mem_buff="${arr[4]}"
mem_cache="${arr[5]}"
swap_si="${arr[6]}"
swap_so="${arr[7]}"

echo "{'hostname':'$hostname','status':'$status','date':'$mydate','mem_swap':'$mem_swap','mem_free':'$mem_free','mem_buff':'$mem_buff','mem_cache':'$mem_cache','swap_si':'$swap_si','swap_so':'$swap_so','msg':'$message','date':'$mydate'}"

rm -f var/run/$server_name.pid
