#!/bin/sh
#Program:
#    Detect the changed system files.
#History:
#    2009.8.31   zhoubo     First release


declare -i date_time=`date +%Y%m%d%H`

cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
#aide是个入侵检测工具，主要用途是检查文本的完整性
/usr/sbin/aide -i
cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide_backup/aide.db.new.gz_$date_time
/usr/sbin/aide --compare > /var/lib/aide/aide_report/aide_report_$date_time

#mail duduface.7258@gmail.com -s "dongguan101-$date_time" < /var/lib/aide/aide_report/aide_report_$date_time
#mail yyi831@gmail.com -s "dongguan101-$date_time" < /var/lib/aide/aide_report/aide_report_$date_time

###################### the aide.db.new.gz only save 7 days ###############################

declare -i time_search=`date -d "7 days ago" +%Y%m%d%H`
rm -f /var/lib/aide/aide_backup/aide.db.new.gz_$time_search
rm -f /var/lib/aide/aide_report/aide_report_$time_search
