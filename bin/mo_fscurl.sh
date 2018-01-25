#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

########################################################################
# mo_fscurl
########################################################################

self_check $server_name

echo $$ > var/run/$server_name.pid

content="test${RANDOM}"
curl -s -d "url=/static/test.txt&content=${content}" 'http://10.10.25.17/dist/distribute.php' -H"host:dist.500wan.com" > /dev/null 2>&1
sleep 60
result=""
ip_list=($*)
for ip in ${ip_list[*]}
do
    status=0
    message="nothing"
    d_content=`curl -s "http://${ip}/static/test.txt" -H'host:static.500.com'`
    if [ "${content}" != "${d_content}" ];then
        status=1
        message="${mydate} ${ip} fs500 synchronize files Unsuccessfully"
    fi
    result="${result},{'hostname':'$hostname','date':'$mydate','status':'$status','msg':'$message'}"
done
echo "[${result:1}]"