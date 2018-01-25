#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

########################################################################
# load   
# hostname uptime proc_r proc_b load_1 load_5 load_15 date
########################################################################

self_check $server_name
echo $$ > var/run/$server_name.pid


msg=`uptime`


uptime=`cat /proc/uptime | awk -F"[. ]" '{print $1}'`


curtime=`date +%s`
starttime_s=`echo "$curtime-$uptime" | bc`


starttime=`date -d @"$starttime_s" "+%Y-%m-%d %T"`

loadmsg=`echo $msg | sed -n 's/^.*load average: \(.*\)$/\1/p' | sed 's/,//g'`
arr=($loadmsg)
load_1="${arr[0]}"
load_5="${arr[1]}"
load_15="${arr[2]}"

msg=`vmstat 10 -n 2| tail -n 1`
arr=($msg)
proc_r="${arr[0]}"
proc_b="${arr[1]}"

if [ `printf "%1.f\n" $load_1` -gt 25 ];then
	message="$mydate $hostname load is $load_1"
	status=3
else 
	if [ `printf "%1.f\n" $load_1` -gt 15 ];then
		message="$mydate $hostname load is $load_1"
		status=1
	fi
fi


if [ -f tmp/mo_load.tmp ]; then
	uptime_old=`cat tmp/mo_load.tmp`
	if [ -z "$uptime_old" ]; then
		uptime_old=0
	fi
fi

if [ "$uptime" -lt "$uptime_old" ]; then
        if [ "$uptime" -lt "3600" ]; then
            uptime_message=`echo "$uptime/60" | bc`
            message="$mydate $hostname has been restarted before $uptime_message mins"
        else
            uptime_message=`echo "$uptime/3600" | bc`
            message="$mydate $hostname has been restarted before $uptime_message hours"
        fi
fi


echo "$uptime" > tmp/mo_load.tmp

tf='tmp/mo_load_new_compare.tmp'
if [ ! -f ${tf} ];then
    echo $load_1 > ${tf}
else
    load_1_p=`cat ${tf}`
    compare_r=`echo "${load_1}-${load_1_p}"|bc -l`
    load_1_check=-5
    if [ $(echo "$compare_r < $load_1_check"|bc) -eq 1 ];then
        if [ $status -eq 3 ];then
            status=1
        fi
    fi
    echo $load_1 > ${tf}
fi

if [ ${status} -gt 0 ];then
    record_ps
fi

echo "{'hostname':'$hostname','uptime':'$uptime','starttime':'$starttime','date':'$mydate','status':'$status','proc_r':'$proc_r','proc_b':'$proc_b','load_1':'$load_1','load_5':'$load_5','load_15':'$load_15','msg':'$message'}"

rm -f var/run/$server_name.pid
