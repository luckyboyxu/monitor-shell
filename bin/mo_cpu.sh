#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0

########################################################################
# mo_cpu
# hostname io_bi io_bo sys_in sys_cs cpu_sy cpu_us cpu_id cpu_wa cpu_st date
########################################################################

self_check $server_name
echo $$ > var/run/$server_name.pid

continuity=5
tmp_file="/tmp/cpu_tmp.txt"
if [ ! -f ${tmp_file} ];then
	echo "0 cpu_us 0" > ${tmp_file}
	echo "0 cpu_sy 0" >> ${tmp_file}
	echo "0 cpu_wa 0" >> ${tmp_file}
fi

message=`vmstat 30 -n 2| tail -n 1`
arr=($message)

io_bi="${arr[8]}"
io_bo="${arr[9]}"
sys_in="${arr[10]}"
sys_cs="${arr[11]}"
cpu_us="${arr[12]}"
cpu_sy="${arr[13]}"
cpu_id="${arr[14]}"
cpu_wa="${arr[15]}"
cpu_st="${arr[16]}"

msg=""

us_time=`cat ${tmp_file} |grep cpu_us|awk '{print $1}'`
sy_time=`cat ${tmp_file} |grep cpu_sy|awk '{print $1}'`
wa_time=`cat ${tmp_file} |grep cpu_wa|awk '{print $1}'`

if [ ${cpu_us} -ge 60 ];then
        let us_time++
        if [ ${us_time} -gt ${continuity} ];then
                if [ ${cpu_us} -ge 80 ];then
                    status=3
                else
                    status=1
                fi
                us_time=0
                msg="${msg};the user time is ${cpu_us}% Exceed 60%;"
        fi
else
        us_time=0
fi
if [ ${cpu_sy} -ge 40 ];then
        let sy_time++
        if [ ${sy_time} -gt ${continuity} ];then
                if [ ${cpu_sy} -ge 60 ];then
                    status=3
                else
                    status=1
                fi
                sy_time=0
                msg="${msg};the system time is ${cpu_sy}% Exceed 40%;"
        fi
else
        sy_time=0
fi
if [ ${cpu_wa} -ge 40 ];then
        let wa_time++
        if [ ${wa_time} -gt ${continuity} ];then
                if [ ${cpu_wa} -ge 60 ];then
                    status=3
                else
                    status=1
                fi
                wa_time=0
                msg="${msg};the waiting time is ${cpu_wa}% Exceed 40%;"
        fi
else
        wa_time=0
fi
if [ ${status} -eq 0 ];then
	msg="nothing"
else
	msg="$msg-more than ${continuity} times" 
	msg=${msg:1}
fi

echo "${us_time} cpu_us ${cpu_us}" > ${tmp_file}
echo "${sy_time} cpu_sy ${cpu_sy}" >> ${tmp_file}
echo "${wa_time} cpu_wa ${cpu_wa}" >> ${tmp_file}

#获取cpu每个核数据
date_now=`date -d "${mydate}" +"%s"`
detail=""
cpux_tmp_bef="/tmp/cpux.tmp.bef"
cpux_tmp_now="/tmp/cpux.tmp.now"
date_bef_file="/tmp/date.tmp.bef"
scale=2
cat /proc/stat|grep "cpu" > $cpux_tmp_now

if [ ! -e $cpux_tmp_bef ];then
	touch $cpux_tmp_bef
else
	while read line
	do
		cpuname=`echo $line|awk '{print $1}'`
		user=`echo $line|awk '{print $2}'`
		nice=`echo $line|awk '{print $3}'`
		system=`echo $line|awk '{print $4}'`
		idle=`echo $line|awk '{print $5}'`
		iowait=`echo $line|awk '{print $6}'`
		irq=`echo $line|awk '{print $7}'`
		softirq=`echo $line|awk '{print $8}'`
		total=`echo $line | awk '{print $2+$3+$4+$5+$6+$7+$8}'`

		data_bef=`cat ${cpux_tmp_bef}|grep ${cpuname}`
		user_bef=`echo $data_bef|awk '{print $2}'`
		nice_bef=`echo $data_bef|awk '{print $3}'`
		system_bef=`echo $data_bef|awk '{print $4}'`
		idle_bef=`echo $data_bef|awk '{print $5}'`
		iowait_bef=`echo $data_bef|awk '{print $6}'`
		irq_bef=`echo $data_bef|awk '{print $7}'`
		softirq_bef=`echo $data_bef|awk '{print $8}'`
		total_bef=`echo $data_bef | awk '{print $2+$3+$4+$5+$6+$7+$8}'`
		
		date_bef=`cat $date_bef_file`
		date_t=`expr $date_now - $date_bef`

		user_t=`expr $user - $user_bef`
		nice_t=`expr $nice - $nice_bef`
		system_t=`expr $system - $system_bef`
		idle_t=`expr $idle - $idle_bef`
		iowait_t=`expr $iowait - $iowait_bef`
		irq_t=`expr $irq - $irq_bef`
		softirq_t=`expr $softirq - $softirq_bef`

		user=`expr ${user_t}/${date_t}/100|bc -l`
		nice=`expr ${nice_t}/${date_t}/100|bc -l`
		system=`expr ${system_t}/${date_t}/100|bc -l`
		idle=`expr ${idle_t}/${date_t}/100|bc -l`
		iowait=`expr ${iowait_t}/${date_t}/100|bc -l`
		irq=`expr ${irq_t}/${date_t}/100|bc -l`
		softirq=`expr ${softirq_t}/${date_t}/100|bc -l`

		sys_total=`expr $total - $total_bef`
		usage=`expr 100-$idle_t/$sys_total*100 |bc -l`
		usage=`echo $usage|awk '{printf("%.2f",$1)}'`

		user=`echo $user|awk '{printf("%.2f",$1)}'`
		nice=`echo $nice|awk '{printf("%.2f",$1)}'`
		system=`echo $system|awk '{printf("%.2f",$1)}'`
		idle=`echo $idle|awk '{printf("%.2f",$1)}'`
		iowait=`echo $iowait|awk '{printf("%.2f",$1)}'`
		irq=`echo $irq|awk '{printf("%.2f",$1)}'`
		softirq=`echo $softirq|awk '{printf("%.2f",$1)}'`

		detail="$detail,{\"cpuname\":\"$cpuname\",\"f_usage\":$usage,\"f_user\":$user,\"f_nice\":$nice,\"f_system\":$system,\"f_idle\":$idle,\"f_iowait\":$iowait,\"f_irq\":$irq,\"f_softirq\":$softirq}"
	done <  $cpux_tmp_now

	detail="[${detail:1}]"
fi
rm -f $cpux_tmp_bef
mv $cpux_tmp_now $cpux_tmp_bef
echo ${date_now} > ${date_bef_file}

echo "{\"status\":$status,\"hostname\":\"$hostname\",\"date\":\"$mydate\",\"io_bi\":$io_bi,\"io_bo\":$io_bo,\"sys_in\":$sys_in,\"sys_cs\":$sys_cs,\"cpu_us\":$cpu_us,\"cpu_sy\":$cpu_sy,\"cpu_id\":$cpu_id,\"cpu_wa\":$cpu_wa,\"cpu_st\":$cpu_st,\"msg\":\"$msg\"}"

rm -f var/run/$server_name.pid

