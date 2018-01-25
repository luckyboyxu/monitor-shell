#coding=gbk

import threading

def lockingCall(lock):
    '''用于添加锁保护的Decorator'''
    def decoFunc(f):
        def callFunc(*args, **kwargs):
            lock.acquire()
            try:
                return f(*args, **kwargs)
            finally:
                lock.release()
        return callFunc
    return decoFunc

class LockingObjectCall:
    '''线程保护类，给对象带__call__的属性添加线程锁保护'''

    def __init__(self, obj, lock=None):
        self._obj = obj
        self._lock = lock or threading.RLock()

    def __getattr__(self, name):
        self._lock.acquire()
        try:
            attr = getattr(self._obj, name)
            if hasattr(attr, '__call__'):
                def myCall(*args, **kwargs):
                    self._lock.acquire()
                    try:
                        return attr(*args, **kwargs)
                    finally:
                        self._lock.release()
                setattr(self, name, myCall)
                return myCall
            else:
                setattr(self, name, attr)
                return attr
        finally:
            self._lock.release()

