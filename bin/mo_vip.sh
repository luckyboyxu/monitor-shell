#! /bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

########################################################################
# 虚ip监控
# mo_vip
# hostname status message date
########################################################################
empty_file="../conf/empty_times"
empty_dir=`dirname $empty_file`

if [ ! -e $empty_dir ];then
        mkdir -p $empty_dir
fi
if [ ! -e $empty_file ];then
        echo "0" > $empty_file
fi
#--------------------------------------------------------------------------------------------------------
#自检程序
self_check $server_name
echo $$ > var/run/$server_name.pid
#------------------------------------------------------------------------------------------------------
#判断网卡名
if [ "$1" == "" ];then
	dev="lo"
	mask_get="255.255.255.255"
else
	if [ "$1" == "lo" ] && [ "$2" != "255.255.255.255" ];then
		echo "{'hostname':'$hostname','status':1,'msg':'dev is $1 but netmask is not 255.255.255.255'}"
		exit 1
	else
		if [ "$2" != "255.255.255.255" ] && [ "$2" != "255.255.255.0" ] && [ "$2" != "255.255.0.0" ] && [ "$2" != "255.0.0.0" ] && [ "$2" != "0.0.0.0" ];then
			echo "{'hostname':'$hostname','status':1,'msg':'netmask $2 error'}"
			exit 1
		fi
	fi
	dev=$1
	mask_get=$2
fi
#判断网卡是否存在
ifconfig $dev >/dev/null 2>&1
if [ $? -ne 0 ];then
        echo "{'hostname':'$hostname','status':1,'msg':'$dev is not exist','date':'$mydate'}"
        exit 1
fi
#获取远程ip列表
ip_mes=$(curl "http://ops.500wan.com/index.php?r=base/default/getVip&hostname=${hostname}&port=${dev}" 2>/dev/null)
#判断接口是否返回正常
echo $ip_mes |grep "</html>"
if [ $? -eq 0 ];then
	echo "{'hostname':'$hostname','status':3,'msg':'get ?r=base/default/getVip failed','date':'$mydate'}"
	exit 1
fi
ip_get=($ip_mes)
#--------------------- ---------------------------------------------------------------------------------
#假如获取远程ip列表为空，判断获取到空列表次数是否为12，是则清空所有虚ip，否则不做任何操作
if [ -z $ip_get ];then
        # status=0
        # message=""
        # empty=`cat $empty_file`
        # if [ $empty != 12 ];then
                # let empty++
                # echo $empty > $empty_file
                # status=0
        # else
                # echo "0" > $empty_file
                # for i in `ifconfig |cut -d' ' -f1|sed '/^$/d'|grep "^lo:"`
                # do
                        # ip=`ifconfig $i|awk '/inet addr/{print $2}'|awk -F: '{print $2}'`
                        # ifconfig $i down 2>/dev/null
                        # [ $? = 0 ] && message="$message;del $ip succeed" || message="$message;del $ip failed"
						# /sbin/route del $ip >/dev/null 2>&1
                # done
                # status=1
				# echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
				# echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
				# echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
				# echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
        # fi
        # [ "$message" = "" ] && status=0 && message=";nothing"
        # echo "{'hostname':'$hostname','status':'$status','msg':${message:1},'date':'$mydate'}"
	# rm -f var/run/$server_name.pid
		echo "{'hostname':'$hostname','status':0,'msg':'Getten vip list is empty','date':'$mydate'}"
        exit 1
fi
if [ "$dev" == "lo" ];then
	echo "0" > $empty_file
	echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
	echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
	echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
	echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
fi
#---------------------------------------------------------------------------------------------------------
#本机没有添加对应网卡虚ip，直接将列表虚ip全部添加
lo_tab=(`/sbin/ifconfig|cut -d' ' -f1|sed '/^$/d'|grep "^${dev}:"`)
if [ -z ${lo_tab} ];then
        message=""
        for ip in ${ip_get[@]}
        do
                ip_num=${ip##*.}
                /sbin/ifconfig ${dev}:${ip_num} $ip netmask $mask_get > /dev/null 2>&1
		echo "/sbin/ifconfig ${dev}:${ip_num} $ip netmask $mask_get > /dev/null 2>&1"
                if [ $? -eq 0 ];then
                        message="$message;add $ip succeed"
                else
                        message="$message;add $ip failed"
                fi
				if [ "$dev" == "lo" ];then
					/sbin/route add -host $ip dev lo:${ip_num}
				fi
        done
		if [ "$dev" == "lo" ];then
			/sbin/sysctl -p >/dev/null 2>&1
		fi
        echo "{'hostname':'$hostname','status':1,'msg':${message:1},'date':'$mydate'}"
else
#----------------------------------------------------------------------------------------------------------
#建立对应网卡对应的ip列表   lo_tab ---> ip_tab
        ip_num=0
        for inet in ${lo_tab[@]}
        do
                ip_tab[${ip_num}]=`/sbin/ifconfig $inet | awk '/inet addr:/{ print $2 }'|awk -F: '{print $2}'`
                let ip_num++
        done
#----------------------------------------------------------------------------------------------------------
#本地ip列表与远程列表比较，删除多余虚ip
        ip_num=0
        message=""
        #ip_get_num=0
        let ip_t_num=${#ip_get[@]}-1
        for ip in ${ip_tab[@]}
        do
                flag=0
                for ip_t in `seq 0 $ip_t_num`
                do
                        if [ "${ip_get[${ip_t}]}" = "${ip}" ];then
                                flag=1
                                unset ip_get[${ip_t}]
                                break
                        fi
                done
                if [ $flag = 0 ];then
                        /sbin/ifconfig ${lo_tab[${ip_num}]} down > /dev/null 2>&1
                        if [ $? = 0 ];then
                                message="$message;del $ip succeed"
                                unset io_tab[${ip_num}]
                                unset ip_tab[${ip_num}]
                        else
                                message="$message;del $ip failed"
                        fi
			if [ "$dev" == "lo" ];then
				route del $ip >/dev/null 2>&1
			fi
                fi
                let ip_num++
        done
#---------------------------------------------------------------------------------------------------------
#将已删减的远程ip列表添加到本地虚ip
        for ip in ${ip_get[@]}
        do
                inet_num=${ip##*.}
                /sbin/ifconfig ${dev}:${inet_num} $ip netmask $mask_get > /dev/null 2>&1
                if [ $? -eq 0 ];then  
                        message="$message;add $ip succeed" 
                else 
                        message="$message;add $ip failed" 
                fi
		if [ "$dev" == "lo" ];then
			/sbin/route add -host $ip dev lo:${inet_num}
		fi
        done
	if [ "$dev" == "lo" ];then
		/sbin/sysctl -p >/dev/null 2>&1
	fi
        if [ "$message" == "" ];then
                message=";nothing"
                status=0
        else
                status=1
        fi
        echo "{'hostname':'$hostname','status':'$status','msg':${message:1},'date':'$mydate'}"
fi
#--------------------------------------------------------------------------------------------------------

rm -f var/run/$server_name.pid
