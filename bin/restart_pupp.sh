#!/bin/bash
. ../conf/globle.cfg
. ../bin/functions.sh
echo `date +%Y%m%d-%X` >> ../var/log/restart_puppet.log
/etc/init.d/puppet restart  >> ../var/log/restart_puppet.log 
