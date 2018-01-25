#!/bin/sh

. conf/globle.cfg
. bin/functions.sh

############################
##  检查当前服务器挂载情况
############################


self_check mount
echo $$ > var/run/mount.pid


#### 获取当前mount列表
df -h > tmp/df_tmp.txt

#### 获取mount配置文件

[ -r "conf/mount_list_$hostip.cfg" ] && conf_file="conf/mount_list_$hostip.cfg" || conf_file="conf/mount_list_globle.cfg"

#### 对比mount列表和配置文件
while read line
do
    grep -q "$line" tmp/df_tmp.txt
    if [ "$?" -ne 0 ];then 
        message="$hostip:$hostname:$line is not mount"
        sendmsg "$message" "$Phone_list" "$prog"
        echo " `date +%Y%m%d-%T`  $hostip:$hostname:$line is not mount" >> var/log/mount.log
    else
        echo " `date +%Y%m%d-%T`  $hostip:$hostname:$line mount is OK" >> var/log/mount.log
    fi
done < $conf_file


rm -f tmp/df_tmp.txt
rm -f tmp/mount.tmp.*
rm -f var/run/mount.pid
