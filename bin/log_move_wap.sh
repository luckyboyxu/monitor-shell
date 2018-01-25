#!/bin/sh

if [ -z "$1" ];then
   time=`date -d 'yesterday' +%Y%m%d`
   time2=`date -d 'yesterday' +%Y_%m_%d`
else
   time=$1
   time2=`date -d "$1" +%Y_%m_%d`
fi

rm -rf /data/log_file_for111/*
mkdir -p /data/log_file_for111/waplog

gzip /data/waplogs/wapwml.500wan.com/log/wapwml.access.log.${time}
gzip /data/waplogs/3g.500wan.com/log/3g.access.log.${time}
gzip /data/waplogs/wap.500.com/log/wap.500.log.${time}
gzip /data/waplogs/3g.500.com/log/3g.500.log.${time}
gzip /data/waplogs/tenpay.3g.500wan.com/log/tenpay.access.log.${time}
gzip /data/waplogs/safelog/3g_captcha_error.log_${time2}
gzip /data/waplogs/safelog/3g_captcha.log_${time2}
gzip /data/waplogs/safelog/3g_errorlogin.log_${time2}
gzip /data/waplogs/safelog/3g_ipuserlimit_errorlogin.log_${time2}
gzip /data/waplogs/safelog/wap_captcha_error.log_${time2}
gzip /data/waplogs/safelog/wap_captcha.log_${time2}
gzip /data/waplogs/safelog/wap_errorlogin.log_${time2}
gzip /data/waplogs/safelog/wap_ipuserlimit_errorlogin.log_${time2}


rsync -az /data/waplogs/wapwml.500wan.com/log/wapwml.access.log.${time}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/3g.500wan.com/log/3g.access.log.${time}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/wap.500.com/log/wap.500.log.${time}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/3g.500.com/log/3g.500.log.${time}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/tenpay.3g.500wan.com/log/tenpay.access.log.${time}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/safelog/3g_captcha_error.log_${time2}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/safelog/3g_captcha.log_${time2}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/safelog/3g_errorlogin.log_${time2}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/safelog/3g_ipuserlimit_errorlogin.log_${time2}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/safelog/wap_captcha_error.log_${time2}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/safelog/wap_captcha.log_${time2}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/safelog/wap_errorlogin.log_${time2}* /data/log_file_for111/waplog/
rsync -az /data/waplogs/safelog/wap_ipuserlimit_errorlogin.log_${time2}* /data/log_file_for111/waplog/

exit 0