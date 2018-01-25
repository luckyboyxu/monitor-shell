#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

mydate=`date "+%Y-%m-%d %H:%M:%S"`
remark="nothing"
status=0
stat='normal'

. conf/globle.cfg
. bin/functions.sh

#####################################################################
#检测phpAgent是否正常
#####################################################################
self_check phpAgent
echo $$ > var/run/phpAgent.pid

#启动phpAgent
function start_phpAgent()
{
    cd /home/www/phpAgent
    sudo -u www /home/www/phpAgent/bin/checkAgent.sh  >/dev/null 2>&1
    echo $(date +%Y%m%d%T) "phpAgent id starting " >> var/log/phpAgent.log

}
#检测存活性
pid=$(ps -ef |grep "\./phpAgent" |grep -v grep |awk '{print $2}')
if [ -z "$pid" ];then
    start_phpAgent
    echo $(date +%Y%m%d%T) "phpAgent id aboard " >> var/log/phpAgent.log
    message="${hostip} phpAgent is aboard"
    sendmsg "$message" "$Phone_list" "phpAgent"
    pidnew=$(ps -ef |grep "\./phpAgent" |grep -v grep |awk '{print $2}')
    stat='aboard but restart success'
    remark='restart OK'
    if [ -z "$pid" ];then
    	status=1
   	stat='aboard and restart failed'
        remark='restart FAILED'
    fi
else
    echo $(date +%Y%m%d%T) "phpAgent id running normal " >> var/log/phpAgent.log

fi

    echo "{'date':$mydate,'stat':$stat,'remark':$remark,'status':$status}"
rm -f /root/crontab/var/run/phpAgent.pid
