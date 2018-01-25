#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

. ../conf/globle.cfg
. ../bin/functions.sh


echo "`date +%Y%m%d-%T` visit_monitor start" >> ../var/log/visit_monitor.log
m=`date "-d 10min ago" +%d/%b/%Y:%H`
n=`date +%Y%m%d%H%M`
t=`date +%M`
s=`echo $t | sed 's/^0\([0-9]\)/\1/g'`

if [ $s -ge 10 -a $s -lt 20 ];then
      grep "$m:0" /var/log/nginx/3g.access.log | awk '{print $1}' >> ../tmp/3g_0.txt
      grep "$m:0" /var/log/nginx/wap.access.log | awk '{print $1}' >> ../tmp/wap_0.txt
      cat ../tmp/3g_0.txt | sort | uniq -c | sort -nr > ../tmp/3g_swap.txt
      cat ../tmp/wap_0.txt | sort | uniq -c | sort -nr > ../tmp/wap_swap.txt
      cat ../tmp/3g_swap.txt >> ../tmp/wap_swap.txt
      while read num ip
      do 
           net=`ipcalc -n $ip/24 | awk -F = '{print $2}'`
	   grep -q "$net" ../conf/baimingdan.txt
           if [ $num -gt 2000 -a $? -ne 0 ];then
                echo "iptables -A INPUT -s $ip -j DROP" >> /home/iptables/be_iptables_$n.sh
		echo "iptables -A INPUT -s $ip -j DROP" >> ../var/log/visit_monitor.log
		message="$hostip:$hostname: iptables drop $ip"
                sendmsg "$message" "$Phone_list2" "$prog"
           fi
      done < ../tmp/wap_swap.txt
      rm -f ../tmp/3g_0.txt
      rm -f ../tmp/wap_0.txt
      [ -e /home/iptables/be_iptables_"$n".sh ] && sh /home/iptables/be_iptables_$n.sh
fi
if [ $s -ge 20 -a $s -lt 30 ];then
      grep "$m:1" /var/log/nginx/3g.access.log | awk '{print $1}' >> ../tmp/3g_10.txt
      grep "$m:1" /var/log/nginx/wap.access.log | awk '{print $1}' >> ../tmp/wap_10.txt
      cat ../tmp/3g_10.txt | sort | uniq -c | sort -nr > ../tmp/3g_swap.txt
      cat ../tmp/wap_10.txt | sort | uniq -c | sort -nr > ../tmp/wap_swap.txt
      cat ../tmp/3g_swap.txt >> ../tmp/wap_swap.txt
      while read num ip
      do
           net=`ipcalc -n $ip/24 | awk -F = '{print $2}'`
	   grep -q "$net" ../conf/baimingdan.txt
           if [ $num -gt 2000 -a $? -ne 0 ];then
                echo "iptables -A INPUT -s $ip -j DROP" >> /home/iptables/be_iptables_$n.sh
		echo "iptables -A INPUT -s $ip -j DROP" >> ../var/log/visit_monitor.log
		message="$hostip:$hostname: iptables drop $ip"
                sendmsg "$message" "$Phone_list2" "$prog"
           fi
      done < ../tmp/wap_swap.txt
      rm -f ../tmp/3g_10.txt
      rm -f ../tmp/wap_10.txt
      [ -e /home/iptables/be_iptables_"$n".sh ] && sh /home/iptables/be_iptables_$n.sh
fi
if [ $s -ge 30 -a $s -lt 40 ];then
      grep "$m:2" /var/log/nginx/3g.access.log | awk '{print $1}' >> ../tmp/3g_20.txt
      grep "$m:2" /var/log/nginx/wap.access.log | awk '{print $1}' >> ../tmp/wap_20.txt
      cat ../tmp/3g_20.txt | sort | uniq -c | sort -nr > ../tmp/3g_swap.txt
      cat ../tmp/wap_20.txt | sort | uniq -c | sort -nr > ../tmp/wap_swap.txt
      cat ../tmp/3g_swap.txt >> ../tmp/wap_swap.txt
      while read num ip
      do
           net=`ipcalc -n $ip/24 | awk -F = '{print $2}'`
	   grep -q "$net" ../conf/baimingdan.txt
           if [ $num -gt 2000 -a $? -ne 0 ];then
                echo "iptables -A INPUT -s $ip -j DROP" >> /home/iptables/be_iptables_$n.sh
		echo "iptables -A INPUT -s $ip -j DROP" >> ../var/log/visit_monitor.log
		message="$hostip:$hostname: iptables drop $ip"
                sendmsg "$message" "$Phone_list2" "$prog"
           fi
      done < ../tmp/wap_swap.txt
      rm -f ../tmp/3g_20.txt
      rm -f ../tmp/wap_20.txt
      [ -e /home/iptables/be_iptables_"$n".sh ] && sh /home/iptables/be_iptables_$n.sh
fi
if [ $s -ge 40 -a $s -lt 50 ];then
      grep "$m:3" /var/log/nginx/3g.access.log | awk '{print $1}' >> ../tmp/3g_30.txt
      grep "$m:3" /var/log/nginx/wap.access.log | awk '{print $1}' >> ../tmp/wap_30.txt
      cat ../tmp/3g_30.txt | sort | uniq -c | sort -nr > ../tmp/3g_swap.txt
      cat ../tmp/wap_30.txt | sort | uniq -c | sort -nr > ../tmp/wap_swap.txt
      cat ../tmp/3g_swap.txt >> ../tmp/wap_swap.txt
      while read num ip
      do
           net=`ipcalc -n $ip/24 | awk -F = '{print $2}'`
	   grep -q "$net" ../conf/baimingdan.txt
           if [ $num -gt 2000 -a $? -ne 0 ];then
                echo "iptables -A INPUT -s $ip -j DROP" >> /home/iptables/be_iptables_$n.sh
		echo "iptables -A INPUT -s $ip -j DROP" >> ../var/log/visit_monitor.log
		message="$hostip:$hostname: iptables drop $ip"
                sendmsg "$message" "$Phone_list2" "$prog"
           fi
      done < ../tmp/wap_swap.txt
      rm -f ../tmp/3g_30.txt
      rm -f ../tmp/wap_30.txt
      [ -e /home/iptables/be_iptables_"$n".sh ] && sh /home/iptables/be_iptables_$n.sh
fi
if [ $s -ge 50 -a $s -le 59 ];then
      grep "$m:4" /var/log/nginx/3g.access.log | awk '{print $1}' >> ../tmp/3g_40.txt
      grep "$m:4" /var/log/nginx/wap.access.log | awk '{print $1}' >> ../tmp/wap_40.txt
      cat ../tmp/3g_40.txt | sort | uniq -c | sort -nr > ../tmp/3g_swap.txt
      cat ../tmp/wap_40.txt | sort | uniq -c | sort -nr > ../tmp/wap_swap.txt
      cat ../tmp/3g_swap.txt >> ../tmp/wap_swap.txt
      while read num ip
      do
           net=`ipcalc -n $ip/24 | awk -F = '{print $2}'`
	   grep -q "$net" ../conf/baimingdan.txt
           if [ $num -gt 2000 -a $? -ne 0 ];then
                echo "iptables -A INPUT -s $ip -j DROP" >> /home/iptables/be_iptables_$n.sh
		echo "iptables -A INPUT -s $ip -j DROP" >> ../var/log/visit_monitor.log
		message="$hostip:$hostname: iptables drop $ip"
                sendmsg "$message" "$Phone_list2" "$prog"
           fi
      done < ../tmp/wap_swap.txt
      rm -f ../tmp/3g_40.txt
      rm -f ../tmp/wap_40.txt
      [ -e /home/iptables/be_iptables_"$n".sh ] && sh /home/iptables/be_iptables_$n.sh
fi
if [ $s -ge 0 -a $s -lt 10 ];then
      grep "$m:5" /var/log/nginx/3g.access.log | awk '{print $1}' >> ../tmp/3g_50.txt
      grep "$m:5" /var/log/nginx/wap.access.log | awk '{print $1}' >> ../tmp/wap_50.txt
      cat ../tmp/3g_50.txt | sort | uniq -c | sort -nr > ../tmp/3g_swap.txt
      cat ../tmp/wap_50.txt | sort | uniq -c | sort -nr > ../tmp/wap_swap.txt
      cat ../tmp/3g_swap.txt >> ../tmp/wap_swap.txt
      while read num ip
      do
           net=`ipcalc -n $ip/24 | awk -F = '{print $2}'`
	   grep -q "$net" ../conf/baimingdan.txt
           if [ $num -gt 2000 -a $? -ne 0 ];then
                echo "iptables -A INPUT -s $ip -j DROP" >> /home/iptables/be_iptables_$n.sh
		echo "iptables -A INPUT -s $ip -j DROP" >> ../var/log/visit_monitor.log
		message="$hostip:$hostname: iptables drop $ip"
                sendmsg "$message" "$Phone_list2" "$prog"
           fi
      done < ../tmp/wap_swap.txt
      rm -f ../tmp/3g_50.txt
      rm -f ../tmp/wap_50.txt
      [ -e /home/iptables/be_iptables_"$n".sh ] && sh /home/iptables/be_iptables_$n.sh
fi
echo "`date +%Y%m%d-%T` visit_monitor end" >> ../var/log/visit_monitor.log