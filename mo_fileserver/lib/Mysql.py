#coding=gbk
'''
MySQLdb的二次封装，并使用了sqlalchemy.pool.QueuePool连接池。
*）依赖于XmlConfig读取xml格式的配置，配置例子：
    <db>
        <mysql>
            <test01 host="192.168.0.254" user="middle" passwd="123456" db="esun_middle" charset="gbk" use_unicode="False" />
            <test02 host="192.168.0.254" user="middle" passwd="123456" db="esun_middle" charset="gbk" use_unicode="False" pooling="pool_size=4;timeout=16;use_threadlocal=True" />
        </mysql>
    </db>
*）参考文档：
    DBAPI-2.0说明：
        http://www.python.org/topics/database/DatabaseAPI-2.0.html
    MySQLdb的参数和用法：
        http://mysql-python.sourceforge.net/MySQLdb.html
    SQLAlchemy连接池的参数和用法：
        http://www.sqlalchemy.org/docs/core/pooling.html
*）运行例子：
        db = Db.Mysql.connect('test01')
        rows = db.query("select %s as unixTime", [time.time()])
        print rows[0]['unixTime']
        row = db.queryOne("select %s as unixTime", [time.time()])
        print row['unixTime']
'''
import MySQLdb

import warnings
warnings.filterwarnings('ignore', module='Mysql', append=1)
warnings.filterwarnings('ignore', module='Db.Mysql', append=1)


############################################################


class Conn:

    def __init__(self, conn):
        self.conn = conn

    def query(self, *args, **kwargs):
        '''查询，返回所有行记录'''
        cur = self.conn.cursor(MySQLdb.cursors.DictCursor)
        cur.execute(*args, **kwargs)
        return cur.fetchall()

    def queryOne(self, *args, **kwargs):
        '''查询，返回单行记录'''
        cur = self.conn.cursor(MySQLdb.cursors.DictCursor)
        cur.execute(*args, **kwargs)
        return cur.fetchone()

    def execute(self, *args, **kwargs):
        '''执行，返回被影响的行数'''
        cur = self.conn.cursor()
        cur.execute(*args, **kwargs)
        return cur.rowcount

    def executeMany(self, *args, **kwargs):
        '''执行，many'''
        cur = self.conn.cursor()
        return cur.executemany(*args, **kwargs)

    def insert(self, *args, **kwargs):
        '''插入，返回自增长字段的值，没有的话返回0'''
        cur = self.conn.cursor()
        cur.execute(*args, **kwargs)
        return cur.lastrowid

    def commit(self):
        '''提交'''
        return self.conn.commit()

    def rollback(self):
        '''回滚'''
        return self.conn.rollback()

    def isAlive(self):
        '''检查是否存活'''
        try:
            self.conn.ping()
        except MySQLdb.OperationalError:
            return 0
        return 1

    def close(self):
        try:
            self.conn.close()
        except:
            pass

    def __del__(self):
        self.close()


def _connect(**conf):
    for i in ['port', 'connect_timeout', 'use_unicode', 'auto_commit']:
        if conf.has_key(i):
            conf[i] = eval(str(conf[i]))
    auto_commit = conf.pop('auto_commit', False)
    init_command = conf.pop('init_command', None)
    conn = MySQLdb.connect(**conf)
    if auto_commit:
        conn.autocommit(auto_commit)
    if init_command:
        conn.cursor().execute(init_command)
    return conn


############################################################


import threading
from sqlalchemy.pool import QueuePool

import XmlConfig
import ThreadUtil

_DB_LOCK_ = threading.RLock() # 保护锁
_DB_POOL_ = {} # 连接池
_DB_INST_ = {} # 连接实例

@ThreadUtil.lockingCall(_DB_LOCK_)
def connect(id, conf=None):
    '''使用连接池连接数据库'''
    if not _DB_POOL_.has_key(id):
        if not conf:
            conf = XmlConfig.get('/db/mysql/' + id)
            poolConf = conf.pop('pooling', 'pool_size=4').split(';')
            poolConf = [i.split('=') for i in poolConf]
            poolConf = dict([(i[0], eval(i[1])) for i in poolConf])
        _DB_POOL_[id] = QueuePool(lambda: _connect(**conf), **poolConf)
    for i in range(_DB_POOL_[id].size() + 1):
        conn = _DB_POOL_[id].connect()
        try:
            conn.ping()
            break
        except MySQLdb.OperationalError:
            conn.invalidate()
    return Conn(conn)

@ThreadUtil.lockingCall(_DB_LOCK_)
def get(id, conf=None):
    '''使用连接实例连接数据库（多线程共用一个连接，线程锁保护）'''
    if not _DB_INST_.has_key(id):
        _DB_INST_[id] = ThreadUtil.LockingObjectCall(connect(id, conf))
    if not _DB_INST_[id].isAlive():
        # get不是每次从pool取得新连接，没有自动重连，这里自己实现
        import os, logging
        logging.error('mysql connection lost [%s] [%s]', os.getpid(), id)
        _DB_INST_[id].close()
        del(_DB_INST_[id])
        _DB_INST_[id] = ThreadUtil.LockingObjectCall(connect(id, conf))
    return _DB_INST_[id]

@ThreadUtil.lockingCall(_DB_LOCK_)
def dispose():
    '''释放连接池'''
    _DB_INST_.clear()
    for id in _DB_POOL_:
        _DB_POOL_[id].dispose()
import atexit
atexit.register(dispose)

