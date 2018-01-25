#!/bin/bash
suffix=`date +%Y%m%d%H%M`

runlog="/root/crontab/var/log/movelog.log"
echo "################################" >> $runlog
echo "#######     $suffix     #######" >> $runlog
echo "1 `ls /var/log/log_file_for111/`" >> $runlog

mv /var/log/log_file_for111/* /data/http_nginx.log

echo "2 mv to /data/http_nginx.log/" >> $runlog

[ -s /var/log/log_file_for111 ]
if [ "$?" != "0" ];then
  mkdir /var/log/log_file_for111
  echo "3 mkdir /var/log/log_file_for111" >> $runlog
fi

[ -s /var/log/httpd/httpdlogfile ]
if [ "$?" != "0" ];then
  mkdir /var/log/httpd/httpdlogfile
  echo "4 mkdir /var/log/httpd/httpdlogfile" >> $runlog
fi

[ -s /var/log/nginx/nginxlogfile ]
if [ "$?" != "0" ];then
  mkdir /var/log/nginx/nginxlogfile
  echo "5 makir /var/log/nginx/nginxlogfile" >> $runlog
fi

[ -s /var/log/log_file_for111/logfile."$suffix" ]
if [ "$?" != "0" ];then
  mkdir /var/log/log_file_for111/logfile."$suffix"
  echo "6 mkdir /var/log/log_file_for111/logfile.$suffix" >> $runlog
fi
########################################################################
#httpd
########################################################################
find /var/log/httpd -type f | grep '\.gz$' > HttpdZip.txt.$$
while read LINE
do
  echo "7 read file HttpdZip.txt.$$ valus $LINE" >> $runlog
  mv "$LINE"  /var/log/httpd/httpdlogfile/
done < HttpdZip.txt.$$
rm -f HttpdZip.txt.$$
########################################################################
#nginx
########################################################################
find /var/log/nginx -type f | grep '\.gz$' > NginxZip.txt.$$
while read LINE
do
  echo "8 read file NginxZip.txt.$$ valus $LINE" >> $runlog
  mv "$LINE" /var/log/nginx/nginxlogfile/
done < NginxZip.txt.$$
rm -f NginxZip.txt.$$


echo "9 `ls /var/log/httpd/httpdlogfile`" >> $runlog
echo "10 `ls /var/log/nginx/nginxlogfile`" >> $runlog
echo "11 mv to /var/log/log_file_for111/logfile.$suffix/" >> $runlog

mv /var/log/httpd/httpdlogfile /var/log/log_file_for111/logfile."$suffix"/
mv /var/log/nginx/nginxlogfile /var/log/log_file_for111/logfile."$suffix"/
