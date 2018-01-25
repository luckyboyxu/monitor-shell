#!/bin/sh

MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

mydate=`date "+%Y-%m-%d %H:%M:%S"`
macfile=$MyPath/tmp/mac_map.txt

mac_map ()
{
   dev_name=$1
   [ -z "$dev_name" ] && return
   rm -f $macfile
   /sbin/ifconfig | grep -A 1 "$dev_name" | awk 'BEGIN{i=0}{if($0~"HWaddr") m[i]=$1" "$NF;if($0~"inet addr") {m[i]=m[i]" "substr($2,6);i++}}END{for (i in m) print m[i]}' >> $macfile
}

#### 获取主机信息
hostname=`hostname`
type="vm_server"
os=`cat /etc/issue | sed -n '1'p`

#### 扫描虚拟网卡接口
mac_map br

if [ -z "`cat $macfile`" ];then
	type="real_server"

        #### 扫描绑定网卡接口
        mac_map bond
        if [ -z "`cat $macfile`" ];then
           #### 扫描物理网卡接口
           mac_map "eth[0-9] "
        fi
	if [ -z "`cat $macfile`" ];then
           #### 扫描板载物理网卡接口
           mac_map "em[0-9] "
        fi
fi

#### 扫描虚拟主机的子机信息
if [ "$type" == "vm_server" ];then
	vm_nu=`xm list | sed '1'd | wc -l`
	i=1
	while [ $i -le $vm_nu  ]
	do
		domain=`xm list | sed '1'd | sed -n "$i"p | awk '{if($1!="Domain-0")print $1}'`
		if [ -n "$domain" ];then
                        subhostlist=`[ -z $subhostlist ] && echo "$domain" || echo "$subhostlist,$domain"`
		fi
		let "i=$i+1"
	done
fi

####  网卡接口信息入库
while read port mac ip
do
   mac=`echo $mac | tr '[A-Z]' '[a-z]' | awk -F":" '{print $1$2"-"$3$4"-"$5$6}'`
   curl -s -d "mac=$mac&hostname=$hostname&port=$port&ip=$ip" "http://moni.500wan.com/index.php?r=mac/replaceMac" >> /dev/null 2>&1
done<$macfile

mac=`cat $macfile |sed -n '1'p| awk '{print $2}'`
rm -f $macfile

####  主机信息入库
curl -s -d "type=$type&hostname=$hostname&subhostlist=$subhostlist&os=$os&lable=null&description=null" "http://moni.500wan.com/index.php?r=device/replaceDevice" >>/dev/null 2>&1
echo "{'hostname':'"$hostname"','mac':'"$mac"','type':'"$type"','os':'"$os"','subhostlist':'"$subhostlist"','date':'"$mydate"','msg':'nothing','status':0}"
