#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

mydate=`date "+%Y-%m-%d %H:%M:%S"`

status=0

. conf/globle.cfg
. bin/functions.sh

########################################################################
# vmstat
########################################################################

self_check load
echo $$ > var/run/vmstat.pid

msg=`vmstat 10 -n 2| tail -n 1`
arr=($msg)

proc_r="${arr[0]}"
proc_b="${arr[1]}"
mem_swap="${arr[2]}"
mem_free="${arr[3]}"
mem_buff="${arr[4]}"
mem_cache="${arr[5]}"
swap_si="${arr[6]}"
swap_so="${arr[7]}"
io_bi="${arr[8]}"
io_bo="${arr[9]}"
sys_in="${arr[10]}"
sys_cs="${arr[11]}"
cpu_us="${arr[12]}"
cpu_sy="${arr[13]}"
cpu_id="${arr[14]}"
cpu_wa="${arr[15]}"
cpu_st="${arr[16]}"
echo "{'status':'$status','date':'$mydate','proc_r':'$proc_r','proc_b':'$proc_b','mem_swap':'$mem_swap','mem_free':'$mem_free','mem_buff':'$mem_buff','mem_cache':'$mem_cache','swap_si':'$swap_si','swap_so':'$swap_so','io_bi':'$io_bi','io_bo':'$io_bo','sys_in':'$sys_in','sys_cs':'$sys_cs','cpu_us':'$cpu_us','cpu_sy':'$cpu_sy','cpu_id':'$cpu_id','cpu_wa':'$cpu_wa','cpu_st':'$cpu_st'}"

rm -f var/run/vmstat.pid
