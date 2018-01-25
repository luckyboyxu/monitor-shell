#!/bin/sh
###################################################################################################
# public function for yunwei monitor
###################################################################################################






##########  ########
sendmsg() 
{
    [ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ] && return -1

    local msg=`echo $1 | sed 's/ /+/g'`
    local phone_list=$2
    local time=`date +%Y%m%d-%T`
    local service=$3
    local level=""

    [ -n "$4" ] && level=$4 || level='alert'
    ret=`curl -s "http://monitor.500wan.com/alertsms.php?time=$time&service=$service&level=$level&phone=$phone_list&content=$msg"` 
    [ "$ret" != "ok" ] && return -1 || return 0
}


################     #################
self_check()
{ # $1 =  
    if [ -e var/run/$1.pid ];then
        pid=`cat var/run/$1.pid`
        #kill $pid
    fi
}

##############    #####################
storage()
{

#####    #####
	time=`date +%Y%m%d" "%T`
	hostname=`hostname`
        local logtime=`date +%Y%m%d%H%M%S`
        local service=$1
        local value=$2
        ret=`curl -s -d "time=$logtime&service=$service&ip=$hostip&hostname=$hostname&value=$value" http://monitor.500wan.com/storage.php`
	[ "$ret" != "ok" ] && return -1 || return 0
}

##############    ################
mq_getlog_msg()
{
    local direct=$1
    local values=$2
    rst=`curl -d "direct=$direct&values=$values" 'http://monitor.500wan.com/mq_getlog.php'`
    if [ $rst = 'ok' ];then
        if [ -e getlog_msg.list ];then
            while read direct2 values2
            do
                curl -d "direct=$direct2&values=$values2" 'http://monitor.500wan.com/mq_getlog.php'
            done < tmp/getlog_msg.list
        fi
    else
        echo $direct $calues >> tmp/getlog_msg.list
    fi
}

############     ##########
record_ps()
{
    local ssh_pid=`ps -ef | grep "/usr/sbin/sshd" | grep -v grep | awk '{print $2}'`
    echo "-17" > /proc/${ssh_pid}/oom_adj

    local logtime=`date +%Y%m%d%H%M%S`
    local dir="var/log/recordps"
    local file="var/log/recordps/${logtime}"
    
    if [ ! -e ${dir} ];then
        mkdir -p ${dir}
    fi
    
    echo "commands: ps -aux | sort -k 3,4 | tail -n 10 " > ${file}
    ps aux | sort -k 3,4 | tail -n 10 >> ${file}
}

#########     ##########
record_ps_msg()
{
    /etc/init.d/rsyslog stop > /dev/null 2>&1
    echo 1 > /proc/sys/vm/block_dump 
    sleep 10s
    echo 0 > /proc/sys/vm/block_dump 
    /etc/init.d/rsyslog start > /dev/null 2>&1
}