#!/bin/sh
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
message="no message"

########################################################################
# mo_iostat
# hostanme partition rrqm_s wrqm_s r_s w_s rsec_s wsec_s 
# avgrq_sz avgqu_sz await svctm util date
########################################################################

self_check $server_name

echo $$ > var/run/$server_name.pid



df -lmP |awk  '/^\/dev/ {print $(1)"\t",$NF}' > tmp/sed.$$

# 30s

if [ -z "`cat /etc/redhat-release | grep "release 6"`" ];then
    ## 6.X以下操作系统
    iostat -x -d 30 2 | awk 'BEGIN{a=0}{if($1=="Device:") a++;if(a>1) print $0}' > tmp/iostat.$$
else
    iostat -p  -x 30 2 | awk 'BEGIN{a=0}{if($1=="Device:") a++;if(a>1) print $0}' > tmp/iostat.$$
fi

result=""
while read partition dirname
do
        status=0
        message="no message"

	dev=`echo $partition | sed s'/\/dev\///'g`
	arr=(`awk '{if($1=="'$dev'")print $0}' tmp/iostat.$$`)
	rrqm_s=${arr[1]}   
	wrqm_s=${arr[2]}   
	r_s=${arr[3]}
	w_s=${arr[4]}
	rsec_s=${arr[5]}
	wsec_s=${arr[6]}
	avgrq_sz=${arr[7]}
	avgqu_sz=${arr[8]}
	await=${arr[9]}
	svctm=${arr[10]}
	util=${arr[11]}

        #if [ $(echo "${util} > 90" | bc) = 1 ];then
        #    message="$mydate $hostname $dirname util:$util"
        #    status=1
        #fi

	result="${result},{'hostname':'$hostname','partition':'$partition','dirname':'$dirname','rrqm_s':'$rrqm_s','wrqm_s':'$wrqm_s','r_s':'$r_s','w_s':'$w_s','rsec_s':'$rsec_s','wsec_s':'$wsec_s','avgrq_sz':'$avgrq_sz','avgqu_sz':'$avgqu_sz','await':'$await','svctm':'$svctm','util':'$util','date':'$mydate','status':'$status','msg':'$message'}"
done < tmp/sed.$$
echo "[${result:1}]"

rm -f tmp/iostat.$$
rm -f tmp/sed.$$
rm -f var/run/$server_name.pid
