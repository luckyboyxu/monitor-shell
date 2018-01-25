#!/bin/sh

MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
result=""

########################################################################
# mo_memcached
# hostname ip port connect memory hits get_ps set_ps status msg date
########################################################################

realip=$hostip

while read ip_port
do
    if [[ "$ip_port" =~ $realip ]];then
        hostip=$(echo $ip_port  | awk '{print $2}')
        port=$(echo $ip_port  | awk '{print $3}')
		server_name=$server_name.$ip.$port

		self_check $server_name
		echo $$ > var/run/$server_name.pid

		interval=30
		TEMPFILE="$MyPath/tmp/memcache.tmp"

		function check_Mem()
		{
			local hostip=$hostip
			local port=$port

			##### 检测set情况
			printf "set key500 0 240 3\r\n500\r\n"| nc $hostip $port > /dev/null
		
			if [ $? -ne 0 ];then
                n=1
                while [ $n -le 3 ]
                do
                    sleep 1
                    printf "set key500 0 240 3\r\n500\r\n"| nc $hostip $port > /dev/null
                    if [ $? -eq 0 ];then
                       break
                    fi
                    let n++
                done
                if [ $n -eq 4 ];then
                    status=3
                    msg="$hostip $port memcache set fail"
					result="$result,{'status':'$status','hostname':'$hostname','date':'$mydate','ip':'${hostip}:${port}','port':'$port','connect':0,'memory':0,'hits':0,'get_ps':0,'set_ps':0,'msg':'$msg'}"

					exit -1
                fi 
			fi
			##### 检测get情况
			ret=`printf "get key500\r\n" | nc $hostip $port| sed -n 2p`
			key=`echo $ret |base64 -i`
			if [ $key != "NTAwDQo=" ];then
                n=1
                while [ $n -le 3 ]
                do
                    sleep 1
                    ret=`printf "get key500\r\n" | nc $hostip $port| sed -n 2p`
                    key=`echo $ret |base64 -i`
                    if [ $key = "NTAwDQo=" ];then
                       break
                    fi
                    let n++
                done
                if [ $n -eq 4 ];then
                    status=3
                    msg="$hostip $port memcache get fail"
                    result="$result,{'status':'$status','hostname':'$hostname','date':'$mydate','ip':'${hostip}:${port}','port':'$port','connect':0,'memory':0,'hits':0,'get_ps':0,'set_ps':0,'msg':'$msg'}"
					exit -1
                fi
			fi


			##### 获取第一次mem状态
			echo stats | nc $hostip $port > $TEMPFILE

			if [ $? -ne 0 ];then
                status=3
				msg="$hostip $port memcache connect fail"
				result="$result,{'status':'$status','hostname':'$hostname','date':'$mydate','ip':'${hostip}:${port}','port':'$port','connect':0,'memory':0,'hits':0,'get_ps':0,'set_ps':0,'msg':'$msg'}"
				exit -1
			fi

			dos2unix $TEMPFILE >> /dev/null 2>&1

			cmd_get=`grep 'STAT cmd_get' $TEMPFILE | cut -d " " -f 3`
			cmd_set=`grep 'STAT cmd_set' $TEMPFILE | cut -d " " -f 3`

			sleep $interval

			##### 获取第二次mem状态
			echo stats | nc $hostip $port > $TEMPFILE

			if [ $? -ne 0 ];then
                status=3
				msg="$hostip $port memcache connect fail"
				result="$result,{'status':'$status','hostname':'$hostname','date':'$mydate','ip':'${hostip}:${port}','port':'$port','connect':0,'memory':0,'hits':0,'get_ps':0,'set_ps':0,'msg':'$msg'}"
			fi

			dos2unix $TEMPFILE >> /dev/null 2>&1

			cmd_get2=`grep 'STAT cmd_get' $TEMPFILE | cut -d " " -f 3`
			cmd_set2=`grep 'STAT cmd_set' $TEMPFILE | cut -d " " -f 3`
			get_hits2=`grep 'STAT get_hits' $TEMPFILE | cut -d " " -f 3`
			curr_connect2=`grep 'STAT curr_connections' $TEMPFILE | cut -d " " -f 3`
			bytes2=`grep -w 'STAT bytes' $TEMPFILE |cut -d " " -f 3`

			##### 计算平均值
			diff_get=$(bc <<< $cmd_get2-$cmd_get)
			diff_set=$(bc <<< $cmd_set2-$cmd_set)
       
			pct_get=$(bc <<< $diff_get/$interval)
			pct_set=$(bc <<< $diff_set/$interval)
			pct_hits=$(bc <<< $get_hits2*100/$cmd_get2)

			msg="no message"
			result="$result,{'status':'$status','hostname':'$hostname','date':'$mydate','ip':'${hostip}:${port}','port':'$port','connect':0,'memory':0,'hits':0,'get_ps':0,'set_ps':0,'msg':'$msg'}"
		}

		############ main

		check_Mem $hostip $port
		rm -f $TEMPFILE
		rm -f var/run/$server_name.pid
    fi
done < conf/memcached.cfg
if [ "$result" == "" ];then
	echo "[{'status':'$status','hostname':'$hostname','date':'$mydate','ip':'0','port':'0','connect':0,'memory':0,'hits':0,'get_ps':0,'set_ps':0,'msg':'no thing'}]"
else
	echo "[${result:1}]"
fi
#hostip=$1
#port=$2


