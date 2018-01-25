#!/bin/sh
############################
##  监控调度
############################

#. ./functions.sh 
. ../conf/globle.cfg

cd $MyPath
[ ! -e var/log ] && mkdir -p var/log
[ ! -e var/run ] && mkdir -p var/run
[ ! -e tmp ] && mkdir tmp

echo >> $RunLog
echo "########################################" >> $RunLog
echo "`date +%Y%m%d-%X`  监控主程序启动.." >> $RunLog

#### 读取当前机器监控列表

[ -r "$MyPath/conf/monitor_list.cfg" ] || echo "配置缺失，监控没有启动..." >> $RunLog || exit -1

host_cfg=`grep "^$hostip" $MyPath/conf/monitor_list.cfg | sed 's/'$hostip'//'`

[ -z "$host_cfg" ] && echo "本机无监控内容" >> $RunLog && exit -1

#### 启动相应的监控进程

for job in $host_cfg
do
    [ -z "`echo $job | grep -E "[a-zA-Z]"`" ] && echo "不能识别的监控配置" >> $RunLog && continue
    
    if [ -r "bin/mo_$job.sh" ] ;then
       sh bin/mo_$job.sh 1>/dev/null 2>&1 & 
       [ "$?" -eq "0" ] && echo "`date +%Y%m%d-%T` mo_$job 已启动" >> $RunLog \
                        || echo "`date +%Y%m%d-%T` mo_$job 启动失败" >> $RunLog
    else
       echo "`date +%Y%m%d-%T` 没有名为 mo_$job 的监控，请检查配置。" >> $RunLog 
    fi

    sleep 5  ##避免同时起太多进程
done

exit 0
