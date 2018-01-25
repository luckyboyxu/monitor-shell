import os
os.system("yum install MySQL-python -y >/dev/null 2>&1")
import MySQLdb
import socket
import commands
import time
import traceback
import urllib
import urllib2

db_host = 'lvs-db.500wan.com'
db_user = 'lvs'
db_passwd = 'lvs@500wan'
db_port = 3306
db_name = 'lvs'
check_time = 0.1
pro = {"tcp":"-t","udp":"-u","fwm":"-f"}
hostname = socket.gethostname()

def sendalert(msg):
    try:
        param = {"type_code":"test_linry2","level":"1","sender":"spider","subject":"mo_lvs.py","content":msg}
        url = "http://ops.500wan.com/index.php?r=alert/interface/alert"
        param_urlencode = urllib.urlencode(param)
        req = urllib2.Request(url = url,data =param_urlencode)
        res_data = urllib2.urlopen(req)
    except:
        pass

while 1:
    try:
        now = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time()))
        conn=MySQLdb.connect(host=db_host,user=db_user,passwd=db_passwd,port=db_port,db=db_name)
        cur=conn.cursor()

        cur.execute("select cluster from lvs_node where master_host='%s' or slave_host='%s'" % (hostname,hostname))
        cluster=cur.fetchone()
        if cluster:
            cluster = cluster[0];
        else:
            continue
        count=cur.execute('select * from lvs_s_rs where cluster = "%s"' % cluster)
        results=cur.fetchall()
        services = {}
        for r in results:
            s_ip = r[1]
            s_port = r[2]
            protocol = r[3]
            rs_ip = r[4]
            rs_port = r[5]
            rs_status = r[9]
            
            if not services.has_key(rs_ip+':'+rs_port):
                services[rs_ip+':'+rs_port] = []
            services[rs_ip+':'+rs_port].append({"s_ip":s_ip,"s_port":s_port,"protocol":protocol,"rs_status":rs_status})
        result_msg = "" 
        result_status = "0" 
        for rs in services:
            rs_ip = rs.split(":")[0]
            rs_port = rs.split(":")[1]
            s = socket.socket()
            s.settimeout(check_time)
            check_rs = (rs_ip,int(rs_port))
            try:
                s.connect(check_rs)
                rs_check = 0
            except socket.error as e:
                rs_check = 1

            s.close()
            for ss in services[rs]:
                if rs_check == 0:
                    cmd = "ipvsadm -a %s %s:%s -r %s:%s >/dev/null 2>&1" % (pro[ss["protocol"]],ss["s_ip"],ss["s_port"],rs_ip,rs_port)
                    (status, output) = commands.getstatusoutput(cmd)
                    if status == 0:
                        result_msg = result_msg + "%s:%s add %s:%s;" % (ss["s_ip"],ss["s_port"],rs_ip,rs_port)
                        result_status = "1"
                    sql_rs_status = '1'
                else:
                    cmd = "ipvsadm -d %s %s:%s -r %s:%s  >/dev/null 2>&1" % (pro[ss["protocol"]],ss["s_ip"],ss["s_port"],rs_ip,rs_port)
                    (status, output) = commands.getstatusoutput(cmd)
                    if status == 0:
                        result_msg = result_msg + "%s:%s del %s:%s;" % (ss["s_ip"],ss["s_port"],rs_ip,rs_port)
                        result_status = "1"
                    sql_rs_status = '2'
                sql = """update lvs_s_rs set rs_status='%s',rs_date='%s'
                         where cluster='%s' and s_ip='%s' and s_port='%s' 
                         and rs_ip='%s' and rs_port='%s' and protocol='%s'
                      """ % (sql_rs_status,now,cluster,ss["s_ip"],ss["s_port"],rs_ip,rs_port,ss["protocol"])
                cur.execute(sql)
        conn.commit()
        cur.close()
        conn.close()
        if result_status == "1":
            msg = now + ' ' + hostname + ' ' + result_msg
            sendalert(msg)
            
        time.sleep(2)
    except MySQLdb.Error,e:
        msg = now + ' ' + hostname + ' ' +  "Mysql Error %d: %s" % (e.args[0], e.args[1])
        #sendalert(msg)
