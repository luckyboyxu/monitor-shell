#coding=gbk
try:
    from ujson import dumps, loads
    from ujson import encode_gbk as write
    from ujson import decode_gbk
    def read(data):
        try:
            return decode_gbk(data)
        except ValueError:
            return eval(data)
except ImportError:
    try:
        from json import read, write
    except ImportError:
        pass
    try:
        from json import dumps, loads
    except ImportError:
        pass

if not locals().has_key('read'):
    def read(data):
        return eval(data)
    def write(data):
        return dumps(data, ensure_ascii=False)
