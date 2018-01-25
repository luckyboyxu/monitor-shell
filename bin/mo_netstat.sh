#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

########################################################################
# mo_netstat
# hostname connection established time_wait syn_recv syn_sent fin_wait1 fin_wait2 close_wait detail date
########################################################################

self_check $server_name
echo $$ > var/run/$server_name.pid

netstat -anp | grep -E '^tcp' | awk '{print $6}' | sort | uniq -c | awk '{print $2,$1}' > tmp/netstat.$$

established=0
time_wait=0
syn_recv=0
syn_sent=0
fin_wait1=0
fin_wait2=0
close_wait=0
connection=0
detail=""

while read tcp_stat num
do
    connection=`echo $connection+$num | bc`
    detail=`[ -z "$detail" ] && echo "$tcp_stat $num" || echo "$detail;$tcp_stat $num"`
    case "$tcp_stat" in
        ESTABLISHED)  established=$num
                      ;;
        TIME_WAIT)    time_wait=$num
                      ;;
        SYN_RECV)     syn_recv=$num
                      ;;
        SYN_SENT)     syn_sent=$num
                      ;;
        FIN_WAIT1)    fin_wait1=$num
                      ;;
        FIN_WAIT2)    fin_wait2=$num
                      ;;
        CLOSE_WAIT)   close_wait=$num
                      ;;
        *)            ;;
     esac
done<tmp/netstat.$$

echo "{'hostname':'$hostname','status':'$status','date':'$mydate','connection':'$connection','established':'$established','time_wait':'$time_wait','syn_recv':'$syn_recv','syn_sent':'$syn_sent','fin_wait1':'$fin_wait1','fin_wait2':'$fin_wait2','close_wait':'$close_wait','detail':'$detail','msg':'$message'}"

rm -f tmp/netstat.$$
rm -f var/run/$server_name.pid
