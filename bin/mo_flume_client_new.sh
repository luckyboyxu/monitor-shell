#!/bin/sh

MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

hostip=`/sbin/ifconfig |grep inet |awk -F ':' '{split($2,d," ");print d[1]}'|sed -n 1p`

hostname=`hostname`
Time=`date +"%F %T"`
result=""

#/bin/sh /usr/local/flume_new/client/flume-ng.sh stop
#echo "{'hostname':'$hostname','date':'$Time','status':'0','topic':'nothing','total':'0','port':'0','num':'0','msg':'nothing'}" | tee -a var/log/monitor.log
#exit 1

curl -s "http://ops.500wan.com/index.php?r=monitor/logclient/countPort&ip=$hostip" > $MyPath/tmp/monitor.$$

get_port=`cat $MyPath/tmp/monitor.$$` 
echo $get_port|grep "</html>"
if [ $? -eq 0 ] || [ "$get_port" == "" ];then
    result="{'hostname':'$hostname','date':'$Time','status':'0','topic':'nothing','total':'0','port':'0','num':'0','msg':'get ?r=monitor/logclient/countPort failed'}" | tee -a var/log/monitor.log
	echo "[{'hostname':'$hostname','date':'$Time','status':'0','topic':'nothing','total':'0','port':'0','num':'0','msg':'get ?r=monitor/logclient/countPort failed'}]"
    exit 1
fi

if [ ! -s tmp/monitor.$$ ];then
  result="{'hostname':'$hostname','date':'$Time','status':'0','topic':'nothing','total':'0','port':'0','num':'0','msg':'nothing'}" | tee -a var/log/monitor.log
  echo "[{'hostname':'$hostname','date':'$Time','status':'0','topic':'nothing','total':'0','port':'0','num':'0','msg':'nothing'}]"
  exit 0
fi

status=0
flag=0
out=""

while read port num topic
do
  realnum=$[$num*2]
  count=`netstat -anp | grep ":$port " | grep ESTABLISHED | grep java | wc -l`
  if [ $count -ne $realnum ];then
    status=1
    flag=1
    message="port=$port should be $realnum, now is $count,flume-ng restarted"
	out="{'hostname':'$hostname','date':'$Time','status':'$status','topic':'$topic','total':'$realnum','port':'$port','num':'$count','msg':'$message'}"
	echo $out >> var/log/monitor.log
    result="$result,{'hostname':'$hostname','date':'$Time','status':'$status','topic':'$topic','total':'$realnum','port':'$port','num':'$count','msg':'$message'}"
  else
    status=0
    message="flume is ok!"
	out="{'hostname':'$hostname','date':'$Time','status':'$status','topic':'$topic','total':'$realnum','port':'$port','num':'$count','msg':'$message'}"
	echo $out >> var/log/monitor.log
    result="$result,{'hostname':'$hostname','date':'$Time','status':'$status','topic':'$topic','total':'$realnum','port':'$port','num':'$count','msg':'$message'}"
  fi
done < tmp/monitor.$$
echo "[${result:1}]"

if [ $flag -eq 1 ];then
  /bin/sh /usr/local/flume_new/client/flume-ng.sh restart 2>&1 >> var/log/monitor.log
  echo "flume-ng.sh restarted" >> var/log/monitor.log
fi
rm tmp/monitor.*