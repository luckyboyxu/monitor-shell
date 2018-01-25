#!/usr/bin/python26
#coding = utf-8 
import pdb
import json
import redis
import os
import time
import sys
import StringIO
import socket
import fcntl
import struct

hostname=sys.argv[1]
addr=sys.argv[2]
port=sys.argv[3]
max_memory=sys.argv[4]
maxclients=sys.argv[5]
msg=''
status="0"
info={}

def check_redis(addr,port,time):
	try :
		global status
		global msg
		global info
		r=redis.Redis(host=addr,port=int(port))
		info=r.info()
		#print info
		if r.ping():
			r.setex("yunwei500esun","yunwei500esun",20)
			v=r.get("yunwei500esun")
			if v=="yunwei500esun" :
				msg=time+"--redis on "+port+" is ok"
				return 1
			else :
				msg=time+"--redis on "+port+" is alive,but set get is not normal"
				status="1"
				return 0 
		else :
			msg=time+"--redis on "+port+" is down"
			status="1"
			return 0 
	except :
		msg=time+"--redis on "+port+" is down"
		status="1"
		print '{"date":'+'"'+mydate+'"'+',"ip":'+'"'+addr+':'+port+'","hostname":"'+hostname+'","msg":'+'"'+msg+'"'+',"port":'+'"'+port+'"'+',"status":'+'"'+status+'"'+',"uptime_in_seconds":"","keyspace_hits":"","keyspace_misses":"","hits_rate":"","connected_clients":"","used_memory":""}'
		exit()


if "__main__" == __name__:
	time=os.popen('date "+%Y-%m-%d %H:%M:%S"').read()
	time = time.strip()
	mydate=time

	check_redis(addr,port,time)
	if 1.0*info["connected_clients"]/int(maxclients) > 0.9:
		status=1
		msg="connected clients reached "+repr(info["connected_clients"])
	if 1.0*info["used_memory_rss"]/int(max_memory) > 0.9:
		status=1
		msg="used memory reached "+ repr(info["used_memory_rss"]) +" on port "+ port
	print '{"date":"'+mydate+'","ip":"'+addr+":"+port+'","hostname":"'+hostname+'","msg":"'+msg+'","port":"'+port+'","status":'+repr(status)+',"uptime_in_seconds":"'+repr(info["uptime_in_seconds"])+'","keyspace_hits":"'+repr(info["keyspace_hits"])+'","keyspace_misses":"'+repr(info["keyspace_misses"])+'","hits_rate":"'+repr(1.0*info["keyspace_hits"]/(info["keyspace_hits"]+info["keyspace_misses"])*100)[:4]+'","connected_clients":"'+repr(info["connected_clients"])+'","used_memory":"'+repr(info["used_memory"])+'"}'
