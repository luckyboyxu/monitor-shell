#!/bin/sh  

MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

status=0
result=""

########################################################################
# mo_varnish
# hostname status msg date n_expired backend_fail client_conn_per_second n_purge s_sess n_object client_drop n_lru_nuked client_req s_pass_per_second n_wrk_drop s_sess_per_second accept_fail backend_retry n_wrk cache_miss_per_second s_pass cache_hit client_conn sm_bfree cache_miss cache_hit_per_second client_req_per_second hits_rate pass_rate
########################################################################
/usr/bin/varnishstat -1 > tmp/.varnish_current 2>&1  
  
if [ ! -f 'tmp/.varnish_last' ]; then  
  mv tmp/.varnish_current tmp/.varnish_last  
  exit 0  
fi
  
awk '  
  FILENAME ~ /last/&& NF >= 3 {  
   old[$1] = $2  
  }  
  
  FILENAME ~ /current/&& NF >= 3 {  
   new[$1] = $2  
  }  
  
  END {  
   interval = new["uptime"] - old["uptime"]  
  
   item="client_conn"  
   unit[item] = "connections"  
   type[item] = "uint32"  
   want[item] = new[item]-old[item]  
  
   item="client_conn_per_second"  
   unit[item] = "connections/s"  
   type[item] = "uint32"  
   want[item] = int(want["client_conn"]/interval)  
  
   item="client_drop"  
   unit[item] = "connections"  
   type[item] = "uint32"  
   want[item] = new[item]-old[item]  
     
   item="client_req"  
   unit[item] = "requests"  
   type[item] = "uint32"  
   want[item] = new[item]-old[item]  
     
   item="client_req_per_second"  
   unit[item] = "requests/s"  
   type[item] = "uint32"  
   want[item] = int(want["client_req"]/interval)  
     
   item="cache_hit"  
   unit[item] = "hits"  
   type[item] = "uint32"  
   want[item] = new[item]-old[item]  
     
   item="cache_hit_per_second"  
   unit[item] = "hits/s"  
   type[item] = "uint32"  
   want[item] = int(want["cache_hit"]/interval)  
     
   item="cache_miss"  
   unit[item] = "miss"  
   type[item] = "uint32"  
   want[item] = new[item]-old[item]  
  
   item="cache_miss_per_second"  
   unit[item] = "miss/s"  
   type[item] = "uint32"  
   want[item] = int(want["cache_miss"]/interval)  
  
   item="backend_fail"  
   unit[item] = "count"  
   type[item] = "uint32"  
   want[item] = new[item]-old[item]  
  
   item="n_object"  
   unit[item] = "objects"  
   type[item] = "uint32"  
   want[item] = new[item]  
  
   item="n_wrk"  
   unit[item] = "threads"  
   type[item] = "uint32"  
   want[item] = new[item]  
  
   item="n_wrk_drop"  
   unit[item]="requets"  
   type[item]="uint32"  
   want[item]=new[item]-old[item]  
  
   item="n_expired"  
   unit[item]="objects"  
   type[item]="uint32"  
   want[item]=new[item]-old[item]  
  
   item="n_lru_nuked"  
   unit[item]="objects"  
   type[item]="uint32"  
   want[item]=new[item]-old[item]  
  
   item="s_sess"  
   unit[item]="sessions"  
   type[item]="uint32"  
   want[item]=new[item]-old[item]  
  
   item="s_sess_per_second"  
   unit[item]="sessions/s"  
   type[item]="uint32"  
   want[item]=int(want["s_sess"]/interval)  
  
   item="s_pass"  
   unit[item]="pass"  
   type[item]="uint32"  
   want[item]=new[item]-old[item]  
  
   item="s_pass_per_second"  
   unit[item]="pass/s"  
   type[item]="uint32"  
   want[item]=int(want["s_pass"]/interval)  
  
   item="n_purge"  
   unit[item]="requets"  
   type[item]="uint32"  
   want[item]=new[item]-old[item]  
  
   item="backend_retry"  
   unit[item]="connections"  
   type[item]="uint32"  
   want[item]=new[item]-old[item]  
  
   item="accept_fail"  
   unit[item]="count"  
   type[item]="uint32"  
   want[item]=new[item]-old[item]  
  
   item="sm_bfree"  
   unit[item]="MB"  
   type[item]="uint32"  
   want[item]=int(new[item]/(1024*1024))  
  
   for(item in want) {  
     printf "%s %d %s %s\n", item, want[item], unit[item],type[item]  
   }     
  
   totallookup = want["cache_hit"]+want["cache_miss"]  
   if (totallookup > 0) {  
     item="hits_rate"  
     unit[item]="hits_rate"  
     type[item]="float"  
     want[item]=want["cache_hit"]*100/totallookup  
     printf "%s %f %s %s\n", item, want[item], unit[item],type[item]  
   }  
   if (want["client_req"] > 0) {  
     item="pass_rate"  
     unit[item]="pass_rate"  
     type[item]="float"  
     want[item]=want["s_pass"]*100/want["client_req"]  
     printf "%s %f %s %s\n", item, want[item], unit[item],type[item]  
   }  
  
  }  
' tmp/.varnish_last tmp/.varnish_current | { while read n v u t  
do  
    result=$result'"'$n'":"'$v'",'
done  
result='{'$result'"hostname":"'$hostname'","msg":"nothing","date":"'$mydate'","status":"0"}'
echo $result
mv tmp/.varnish_current tmp/.varnish_last
}