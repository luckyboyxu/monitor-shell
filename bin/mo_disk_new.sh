#! /bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
msg="nothing"
########################################################################
# mo_disk
# hostname partition dirname percent size used avail date
########################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

tmp_file="tmp/diskuse_new.txt"
tmp_file_t="tmp/diskuse_new_t.txt"


if [ ! -e ${tmp_file} ];then
    for disk_msg in `df -lmP |awk  '/^\/dev/ {gsub("%","",$(NF-1));print $1}'`
    do
    #磁盘,告警次数,磁盘空间使用率,时间（年月日）,11点告警次数,15点告警次数,22点告警次数
	echo "${disk_msg} 0 -1 $(date '+%Y_%m_%d') 0 0 0" >> ${tmp_file}
    done
fi

now_h=$(date '+%H')
now_w=$(date '+%w')
now_d=$(date '+%Y_%m_%d')

result=""

for disk_msg in `df -lmP |awk  '/^\/dev/ {gsub("%","",$(NF-1));print $(1)","$(NF-4)","$(NF-3)","$(NF-2)","$(NF-1)","$NF}'`
do
	status=0
	partition=`echo $disk_msg|awk -F',' '{print $1}'`
	dirname=`echo $disk_msg|awk -F',' '{print $NF}'`
	size=`echo $disk_msg|awk -F',' '{print $2}'`
	used=`echo $disk_msg|awk -F',' '{print $3}'`
	avail=`echo $disk_msg|awk -F',' '{print $4}'` 
        percent=`echo $disk_msg|awk -F',' '{print $5}'`
	
	unset tmp
	tmp_msg=`grep ${partition} ${tmp_file}`    
	for i in `seq 1 7`;do        
        	tmp[$i]=`echo ${tmp_msg}|cut -d ' ' -f $i`
	done
	if [ "$now_d" != "${tmp[4]}" ];then
		tmp[4]=$now_d
        	tmp[5]=0
	        tmp[6]=0
       		tmp[7]=0
	fi

	if [ $percent -ge 96 ]
	then
		status=3
		result="$result,{'hostname':'$hostname','status':3,'f_partition':'$partition','percent':$percent,'dirname':'$dirname','size':$size,'used':$used,'avail':$avail,'msg':'$hostname $dirname percent $percent%','date':'$mydate'}" 
	elif [ $percent -ge 90 ]
	then
		percent_pre=${tmp[3]}
		let percent_incre=percent-percent_pre
		if [ ${percent_pre} -ne -1 -a ${percent_incre} -ge 1 ];then
            if [ ${percent_incre} -gt 1 ];then
                status=3
            else
                status=1
            fi
			result="$result,{'hostname':'$hostname','status':$status,'f_partition':'$partition','percent':$percent,'dirname':'$dirname','size':$size,'used':$used,'avail':$avail,'msg':'$hostname $dirname percent $percent%,increase $percent_incre%','date':'$mydate'}" 
		else
			first_time=${tmp[2]}
			if [ ${first_time} -eq 0 ];then
				status=1
				result="$result,{'hostname':'$hostname','status':1,'f_partition':'$partition','percent':$percent,'dirname':'$dirname','size':$size,'used':$used,'avail':$avail,'msg':'$hostname $dirname percent $percent%','date':'$mydate'}"
			else
				if [ $now_h -eq 11 -a ${tmp[5]} -eq 0 ];then
					status=1
				elif [ $now_h -eq 15 -a ${tmp[6]} -eq 0 ];then 
					status=1
				elif [ $now_w -eq 0 -o $now_w -eq 6 ] && [ $now_h -eq 22 -a ${tmp[7]} -eq 0 ];then
					status=1
				fi
				if [ ${status} -eq 1 ];then
					result="$result,{'hostname':'$hostname','status':1,'f_partition':'$partition','percent':$percent,'dirname':'$dirname','size':$size,'used':$used,'avail':$avail,'msg':'$hostname $dirname percent $percent%','date':'$mydate'}"
				else
					result="$result,{'hostname':'$hostname','status':0,'f_partition':'$partition','percent':$percent,'dirname':'$dirname','size':$size,'used':$used,'avail':$avail,'msg':'nothing','date':'$mydate'}"
				fi
			fi
		fi
	else
		let tmp[2]=0
                let tmp[5]=0
                let tmp[6]=0
                let tmp[7]=0
		result="$result,{'hostname':'$hostname','status':0,'f_partition':'$partition','percent':$percent,'dirname':'$dirname','size':$size,'used':$used,'avail':$avail,'msg':'nothing','date':'$mydate'}"
	fi
	if [ $status -eq 1 ];then
		let tmp[2]++
                if [ $now_h -eq 11 ];then
                        let tmp[5]++
                elif [ $now_h -eq 15 ];then
                        let tmp[6]++
                elif [ $now_w -eq 0 -o $now_w -eq 6 ] && [ $now_h -eq 22 ];then
                        let tmp[7]++
                fi
	fi
        tmp[3]=$percent
        #disk_t=${partition##*/}
        #sed -i /$disk_t/d ${tmp_file}
        echo ${tmp[*]} >> ${tmp_file_t}
done			
echo "[${result:1}]"
rm -f ${tmp_file}
mv ${tmp_file_t} ${tmp_file}
rm -f var/run/$server_name.pid
