#! /bin/bash
#! /bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
msg="nothing"
########################################################################
# mo_putfsconf
# report the fileserver queue configure to redis
########################################################################
self_check $server_name
echo $$ > var/run/$server_name.pid

php ./bin/putfsconf.php $hostname > /dev/null &2>1

echo "{'hostname':'$hostname','status':'0','date':'$mydate','msg':'$msg'}"