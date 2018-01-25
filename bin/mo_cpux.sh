#! /bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0

########################################################################
# mo_cpux
# hostname cpuname usage user nice system idle iowait irq softirq date
########################################################################

self_check $server_name
echo $$ > var/run/$server_name.pid

db_host="yw-show-rw.500my.com"
db_port="3306"
username="ywshow"
password="show!@#yw"
db_name="yw_show"
tab_name="mo_cpux"

cpux_tmp_bef="/tmp/cpux.tmp.bef"
cpux_tmp_now="/tmp/cpux.tmp.now"
date_bef_file="/tmp/date.tmp.bef"
msg=""
scale=2
date_now=`date +%s`
cat /proc/stat|grep "cpu" > $cpux_tmp_now

if [ ! -e $cpux_tmp_bef ];then
	touch $cpux_tmp_bef
fi
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

	#user=$(bc <<< "scale=${scale};${user_t}/${date_t}")
	#nice=$(bc <<< "scale=${scale};${nice_t}/${date_t}")
	#system=$(bc <<< "scale=${scale};${system_t}/${date_t}")
	#idle=$(bc <<< "scale=${scale};${idle_t}/${date_t}")
	#iowait=$(bc <<< "scale=${scale};${iowait_t}/${date_t}")
	#irq=$(bc <<< "scale=${scale};${irq_t}/${date_t}")
	#softirq=$(bc <<< "scale=${scale};${softirq_t}/${date_t}")

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

	sql="insert into ${tab_name}(hostname,status,cpuname,f_usage,f_user,f_nice,f_system,f_idle,f_iowait,f_irq,f_softirq,msg,date) values('$hostname',0,'$cpuname',$usage,$user,$nice,$system,$idle,$iowait,$irq,$softirq,'nothing','$mydate')"
	mysql -h${db_host} -P${db_port} -u${username} -p${password} ${db_name} -e "${sql}"
	msg="$msg,{\"hostname\":\"$hostname\",\"status\":$status,\"msg\":\"nothing\",\"cpuname\":\"$cpuname\",\"f_usage\":$usage,\"f_user\":$user,\"f_nice\":$nice,\"f_system\":$system,\"f_idle\":$idle,\"f_iowait\":$iowait,\"f_irq\":$irq,\"f_softirq\":$softirq,\"date\":\"$mydate\"}"
done <  $cpux_tmp_now
msg="[${msg:1}]"
echo ${date_now} > ${date_bef_file}
fname=${0%%.*}
fname=${fname##*/}
tmp="bin/${fname}"
echo ${msg} > ${tmp}
echo ${msg}

#python bin/make_redis.py ${fname}_t-${hostname} ${tmp}
#echo ${msg}
rm -f $cpux_tmp_bef
mv $cpux_tmp_now $cpux_tmp_bef
rm -f var/run/$server_name.pid
rm -f ${tmp}