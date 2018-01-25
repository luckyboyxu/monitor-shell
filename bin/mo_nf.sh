#!/bin/sh
num=`cat /proc/net/nf_conntrack | wc -l`
echo "`date +%Y%m%d-%T` $num" >> ../var/log/nf.log