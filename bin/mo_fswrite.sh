#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message=""

########################################################################
# mo_fswrite
########################################################################

self_check $server_name

echo $$ > var/run/$server_name.pid

tmp_file="tmp/fileserver.tmp"
date_now=`date +%s`
if [ -f "/tmp/fileserver.tmp" ];then
    date_500=`cat /tmp/fileserver.tmp`
    if [ "${date_500}" != "" ];then
        let date_cp=date_now-date_500
        if [ ${date_cp} -ge 3600 ];then
            status=1
            message="$hostname rms_fileserver not receive data in 1 hour"
            echo "${mydate} fileserver date_now:${date_now} date_500:${date_500}" >> ${tmp_file}
        fi
    fi
fi

if [ -f "/tmp/fileserver_cn.tmp" ];then
    date_cn=`cat /tmp/fileserver_cn.tmp`
    if [ "${date_cn}" != "" ];then
        let date_cp=date_now-date_cn
        if [ ${date_cp} -ge 3600 ];then
            status=1
            if [ "${message}" == "" ];then
                message="$hostname rms_fileserver_cn not receive data in 1 hour"
            else
                message="${message},rms_fileserver_cn not receive data in 1 hour"
            fi
            echo "${mydate} fileserver_cn date_now:${date_now} date_cn:${date_cn}" >> ${tmp_file}
        fi
    fi
fi
if [ "${message}" == "" ];then
    message="nothing"
fi

echo "{'hostname':'$hostname','date':'$mydate','status':'$status','msg':'$message'}"
