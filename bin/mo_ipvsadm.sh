#!/bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

########################################################################
# mo_ipvsdam
# hostname activeconn inactconn date msg
########################################################################

self_check $server_name
echo $$ > var/run/$server_name.pid

tmp_file="/tmp/ipvs.tmp"
/sbin/ipvsadm -L -n > $tmp_file
vs_ip=""
vs_port=""
result=""
while read VAL1 VAL2 VAL3 VAL4 VAL5 VAL6 VAL7; do
    if [ "$VAL1" = "TCP" ] || [ "$VAL1" = "UDP" ] ; then
	vs_ip=`echo $VAL2|awk -F':' '{print $1}'`
        vs_port=`echo $VAL2|awk -F':' '{print $2}'`
    elif [ "$VAL3" = "Route"  ] || [ "$VAL3" = "Masq"  ] || \
	[ "$VAL3" = "Tunnel" ] || [ "$VAL3" = "Local" ]; then
        rs_ip=`echo $VAL2|awk -F':' '{print $1}'`
        activeconn=${VAL5}
	inactconn=${VAL6}
        result=${result}',{"hostname":"'${hostname}'","status":"0","date":"'${mydate}'","msg":"nothing","vip":"'${vs_ip}'","rip":"'${rs_ip}'","port":"'${vs_port}'","activeconn":"'${activeconn}'","inactconn":"'${inactconn}'"}'
    fi
done < $tmp_file
echo "[${result:1}]"
rm -f $tmp_file
rm -f var/run/$server_name.pid
