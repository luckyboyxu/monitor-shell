#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

#####################################################################
# mo_phpAgent
#####################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

tmp_flag="tmp/mo_phpAgent_new.tmp"
if [ ! -f ${tmp_flag} ];then
    echo 0 > ${tmp_flag}
fi

# start phpAgent
function start_phpAgent()
{
    cd /home/www/phpAgent
    sudo -u www /home/www/phpAgent/bin/checkAgent.sh  >/dev/null 2>&1
    cd $MyPath
}

# check process
pid=$(ps -ef |grep "\./phpAgent" |grep -v grep |awk '{print $2}')
if [ -z "$pid" ];then
    status=1
    start_phpAgent
    pidnew=$(ps -ef |grep "\./phpAgent" |grep -v grep |awk '{print $2}')
    if [ -z "$pidnew" ];then
         message="$mydate $hostname phpAgent is down and restart fail"
    else
         message="$mydate $hostname phpAgent is down but restart ok"
    fi
else
    port=`netstat -lnp | grep phpAgent`
    if [ -z "$port" ];then
        status=3
        message="$mydate $hostname phpAgent port is down"
    fi
fi

# check connect
clients=`netstat -alnp | grep phpAgent |wc -l`
if [ $clients -gt 100 ];then
     status=3
     message="$mydate $hostname phpAgent clients reached $clients"
fi

# check log
heart_log=`ls /data/serlog/config/configclient* | sort | tail -1`
nowtime=`date +%s`
sort -r /data/serlog/config/Rhome.www.phpAgent.bin.phpAgent.log > /root/crontab/tmp/log.list

lastdate=`tail -1 $heart_log | awk '{print $2}'`
if [ -z "$lastdate" ];then
        status=3
        message="$mydate $hostname phpAgent stoped"
else
	lasttime=`date -d "$lastdate"  +%s`
	let "lastpass=$nowtime-$lasttime"
	if [ $lastpass -gt 60 ];then
		status=1
		start_phpAgent
                pidnew=$(ps -ef |grep "\./phpAgent" |grep -v grep |awk '{print $2}')
                if [ -z "$pidnew" ];then
                    status=3
                    echo 1 > ${tmp_flag}
                    message="$mydate $hostname phpAgent write log stop and restart fail"
                else
                    restart_flag=`cat ${tmp_flag}`
                    if [ $restart_flag -eq 1 ];then
                        status=3
                    else
                        echo 1 > ${tmp_flag}
                    fi
                    message="$mydate $hostname phpAgent write log stop but restart ok"
                fi
    else
        echo 0 > ${tmp_flag}
	fi
fi

while read line
do
	logdate=`echo $line | awk -F'[,|[]' '{print $2}'`
	logtime=`date -d "$logdate"  +%s`
	let "passtime=$nowtime-$logtime"
	if [ $passtime -lt 300 ];then
		echo $line | grep 'RETURN:\[\]' > /dev/null 
		if [ $? -eq 0 ];then
			status=1
			mod=`echo $line | awk -F'[]|[]' '{print $6}'`
			z_site=`echo $line | awk -F'[]|[]' '{print $4}'`
                        message="$mydate $hostname phpAgent $z_site $mod return null"
		fi
	else
		break
	fi
done < /root/crontab/tmp/log.list

echo "{'hostname':'$hostname','date':'$mydate','msg':'$message','status':'$status','clients':'$clients'}"
rm var/run/$server_name.pid
