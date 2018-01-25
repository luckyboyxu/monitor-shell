#coding=utf-8

import os
import re
import time
import socket
import fcntl
import struct
import commands
import datetime
import subprocess
import traceback
import lib.Mysql as Mysql
import lib.XmlConfig as XmlConfig
import lib.JsonUtil as JsonUtil
import threading
import Config as C



XmlConfig.setEncoding('gbk')
XmlConfig.loadFile('etc/db.xml')

   
 
class DataCete(threading.Thread):
    def __init__(self, args):
        threading.Thread.__init__(self)
        self.type = args[0]
        self.path = args[1]
        self.server_name = args[2]
        self.lineNum = args[3]
        self.p = None
        self._Func = {
                        'fileServe': [self.analysis_fileSever,self.path],
                        'web'      : [self.analysis_web, self.path],
                     }
        self.nowTime = datetime.datetime.now() - datetime.timedelta(minutes=1)
        
    def get_server_id( self, server_name):
        try:
            db = Mysql.connect('ywshow')
            sql = "SELECT f_serverid serverid FROM `mo_config` WHERE f_servername=%s "
            res = db.query(sql,[server_name])
            if not res:
                print 'the server_name not find !'
            return res[0]['serverid']
        except:
            print 'some error in get_server_id: %s' % traceback.format_exc()
           
    def upExtend(self, serverid,host):
        try:
            db = Mysql.connect('ywshow')
            res = db.query("select f_serverip serverip from mo_extend where f_serverid=%s", [serverid])
            if not res:
                db.execute("insert into mo_extend (f_serverid,f_serverip) values ( %s, %s )",[serverid,host])
            else:
                sip = res[0]['serverip'].split(',')
                if host not in sip:
                    sip.append(host)
                    sip = ','.join(sip)
                    db.execute("update mo_extend set f_serverip=%s where f_serverid=%s",[sip, serverid])    
        except:
            print 'some error in handDb: %s' % traceback.format_exc()
        
    #数据入库       
    def handDb( self, server_id, data):
        try:
            host = get_ip_address()
            db = Mysql.connect('ywshow')
            ret = db.execute("insert into mo_server (f_serverid,f_data,f_serverip,f_instime) values(%s,%s,%s,now())",
                    [server_id,JsonUtil.write(data),host])
            if not ret:
                print 'insert faild !'
            self.upExtend( server_id, host )
        except:
            print 'some error in handDb: %s' % traceback.format_exc()
    
    #解析文件服务数据  
    def analysis_fileSever(self):
        data = {'recv': 0,       'send':0,       'write_ok': 0,
                'write_fail': 0, 'recv_size':0,  'send_fail':0,
                'time':time.time(),
               }
        for line in self.p.stdout.readlines():
            if C.fs['recv'] in line:
                data['recv'] += 1
                ret = line.find('size:')
                if not ret:
                    continue
                data['recv_size'] += float(line[ret+5:])
            elif C.fs['send'] in line: data['send'] += 1
            elif C.fs['write_ok'] in line: data['write_ok'] += 1
            elif C.fs['write_fail'] in line: data['write_fail'] += 1
            elif C.fs['send_fail'] in line: data['send_fail'] += 1
            else: continue
        return data
    
	#解析站点数据
    def analysis_web(self):
        Data = {'recv': 0, 'ip': {},  'recv_size':0,
                'send': 0, 'time':time.time() 
               }
        for line in self.p.stdout.readlines():
            if C.web['recv'] in line:
                data = line.split(':')
                ip = data[3][0:-4].strip()
                if Data['ip'].has_key(ip):
                    Data['ip'][ip] += 1
                else:
                    Data['ip'][ip] = 1
                if data[-1].strip().isdigit():
                    Data['recv_size'] += int(data[-1])
                Data['recv'] += 1
            elif C.web['send'] in line:
                Data['send'] += 1
            else:
                continue
        return Data
            
    def run(self):
        try:
            server_id = self.get_server_id( self.server_name )
            if not server_id:
                print 'server_id is none!'
                return 
            func = self._Func.get( self.type )
            if not func:
                print 'not find the type'
                return
            #n = getLineNumber( self.lineNum, self.nowTime, func[1]  )
            n = self.lineNum
            dt = "'%s'"%self.nowTime.strftime("%Y-%m-%d %H:%M")
            cmd = "tail -n " + str(n) +' ' + func[1] + "| grep " + dt
            self.p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            data = func[0]()
            self.p.terminate()
            self.handDb(server_id,data)
        except:
            print 'some error in doWork: %s' % traceback.format_exc()
''' 
c = threading.RLock()
           
#所查询的行数           
def getLineNumber( n, current_time, path ):
    try:
        cmd = "tail -n " + str(n)  + ' ' + path + "| sed -n 1p"
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        content = p.stdout.readlines()[0]
        #t_str = content[1:20]
        m = re.search('\[(\d+-\d+-\d+\ \d+\:\d+\:\d+)',content)
        if not m:
            return 20000
        t_str = m.group(1)        
        with c:
            Time = datetime.datetime.strptime(t_str.strip(),'%Y-%m-%d %H:%M:%S')
        if Time < current_time:
            p.terminate()
            return n
        else:
           n = n + 5000
           ln = getLineNumber( n, current_time, path )
        return ln
    except:
        print 'some error in doWork: %s' % traceback.format_exc()
''' 

def get_ip_address(ifname = 'eth0'):
    '''获取服务器ip'''
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915, # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])
    
            
def Work():
    Thread = []
    for n in C.TASK:
        if not os.path.exists( n[1] ):
            break
        t = DataCete( n )
        t.setDaemon(True)
        t.start()
        Thread.append(t)
    for t in Thread:
        t.join()

        
        
if __name__ == '__main__':
    st = time.time()
    Work()
    print 'const time: %s'%(time.time() - st)
    
    
