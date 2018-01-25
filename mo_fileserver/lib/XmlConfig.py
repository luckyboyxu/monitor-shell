#coding=gbk
''' XML���ù�����
*��ʹ��ʾ����
    �����и�asdf.xml�ļ�������
    <a>
        <b>bb</b>
        <c c1="cc" c2="ccc"/>
    </a>
    ���Դ��룺
    XmlConfig.loadFile('asdf.xml')
    print XmlConfig.get('/a/b')
    print XmlConfig.get('/a/c')
    print XmlConfig.list('/a/') # ע��"a"�����"/"
'''
import pyDes
import base64

import XmlUtil


_DATAS_ = {}
_FILES_ = {}
_ENCODING_ = 'utf8'
_3DES_OBJ_ = None


def setEncoding(enc):
    global _ENCODING_
    _ENCODING_ = enc


def set_3des_key(key):
    global _3DES_OBJ_
    if len(key) not in [16, 24]:
        import hashlib
        key = hashlib.md5(key).hexdigest()[:24]
    _3DES_OBJ_ = pyDes.triple_des(key, padmode=pyDes.PAD_PKCS5)


def encrypt(data):
    return 'XC#' + base64.encodestring(_3DES_OBJ_.encrypt(data)).strip() + '#CX'


def decrypt(data):
    if data[:3] == 'XC#' and data[-3:] == '#CX':
        return _3DES_OBJ_.decrypt(base64.decodestring(data[3:-3]))
    else:
        return data


def get(path, df=None):
    """��ȡָ��xpath����
    """
    return _DATAS_.get(path, df)


pylist = list
def list(path):
    """��ȡָ��xpath�ڵ��嵥
    """
    pos = len(path)
    return dict([(i[pos:], _DATAS_[i]) for i in _DATAS_ if i.find(path) == 0])


def setData_(p, data, xlist=True):
    """��������
        p       ��ǰxpath
        data    ����dict����list
        xlist   �ظ���xpath�ϲ���list
    """
    if _3DES_OBJ_:
        if isinstance(data, str):
            data = decrypt(data)
        elif isinstance(data, dict):
            data = dict([(k, decrypt(v)) for k, v in data.items()])
    if not xlist or not _DATAS_.get(p):
        _DATAS_[p] = data
    elif isinstance(_DATAS_[p], pylist):
        if _DATAS_[p][-1]:
            if data:
                _DATAS_[p].append(data)
        else:
            _DATAS_[p][-1] = data
    else:
        _DATAS_[p] = [_DATAS_[p], data]


def loadData_(data, p, xlist=True):
    """��������
        data    ����dict����list
        p       ��ǰxpath
        xlist   �ظ���xpath�ϲ���list
    """
    if not isinstance(data, pylist):
        data = [data]
    for d in data:
        if d.has_key('<text>'):
            setData_(p, d.pop('<text>').strip(), xlist)
        if d.has_key('<attrs>'):
            setData_(p, d.pop('<attrs>'), xlist)
        for k, v in d.items():
            loadData_(v, p + '/' + k, xlist)


def loadFile(fname, xlist=True):
    """�����ļ�
        fname   �ļ���
        xlist   �ظ���xpath�ϲ���list
    """
    if _FILES_.has_key(fname):
        return 0
    global _ENCODING_
    dom = XmlUtil.parseFile(fname)
    data = XmlUtil.domToDict(dom, _ENCODING_, xlist=xlist)
    dom.unlink()
    loadData_(data, '', xlist)
    _FILES_[fname] = xlist
    return 1


def loadString(xmlstr, xlist=True):
    """�����ַ���
        xmlstr  �ַ���
        xlist   �ظ���xpath�ϲ���list
    """
    global _ENCODING_
    dom = XmlUtil.parseString(xmlstr)
    data = XmlUtil.domToDict(dom, _ENCODING_, xlist=xlist)
    dom.unlink()
    loadData_(data, '', xlist)


if __name__ == '__main__':
    import sys
    if len(sys.argv) != 4:
        print 'usage: %s <-d|-e> <key> <data>' % sys.argv[0]
        sys.exit(1)
    set_3des_key(sys.argv[2])
    if sys.argv[1] == '-d':
        print decrypt(sys.argv[3])
    else:
        print encrypt(sys.argv[3])

