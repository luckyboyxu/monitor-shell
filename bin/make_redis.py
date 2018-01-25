#! /usr/bin/env python
import sys
import redis

key = sys.argv[1]
file = sys.argv[2]

fp = open(file,"rb") 
value = fp.readline().splitlines( )
fp.close() 

r = redis.Redis(host='10.10.25.84', port=6379)
r.set(key, value[0]) 