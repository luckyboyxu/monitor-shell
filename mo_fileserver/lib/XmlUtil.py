#coding=gbk
"""XML Utilities (minidom)
"""
import re
from xml.dom import minidom


def parseString(s):
    """把字符串解析成minidom
    """
    if s[:5] == '<?xml':
        ss = s.split('?>', 1)
        m = re.search(r'encoding=\W([\w\-]+)\W', ss[0])
        if m:
            s = ss[1].decode(m.group(1)).encode('utf8')
        else:
            s = ss[1]
    return minidom.parseString(s)


def parseFile(fname):
    """把文件解析成minidom
    """
    f = open(fname, 'r')
    s = f.read()
    f.close()
    return parseString(s)


def parseToDict(s, encoding='utf8', xlist=False):
    """把minidom解析成dict
        s           字符串
        encoding    输出dict的字符集
        xlist       重复的xpath合并成list
    """
    dom = parseString(s)
    data = domToDict(dom, encoding, xlist=xlist)
    dom.unlink()
    return data


def domToDict(node, encoding='utf8', data=None, xlist=False):
    """把minidom解析成dict
        node        minidom当前节点
        encoding    输出dict的字符集
        data        dict的当前节点
        xlist       重复的xpath合并成list
    """
    if data == None:
        data = {}
    if node.nodeType == node.DOCUMENT_NODE:
        domToDict(node.firstChild, encoding, data, xlist)
        return data
    d = {}
    if node.hasChildNodes():
        for i in node.childNodes:
            if i.nodeType == i.TEXT_NODE:
                if d.has_key('<text>'):
                    d['<text>'] += i.nodeValue.encode(encoding)
                else:
                    d['<text>'] = i.nodeValue.encode(encoding)
            elif i.nodeType == i.ELEMENT_NODE:
                domToDict(i, encoding, d, xlist)
    if node.hasAttributes():
        d['<attrs>'] = dict([(i[0].encode(encoding), i[1].encode(encoding))
                                for i in node.attributes.items()])
    node_name = node.nodeName.encode(encoding)
    if not xlist or not data.has_key(node_name):
        data[node_name] = d
    elif type(data[node_name]) is list:
        data[node_name].append(d)
    else:
        data[node_name] = [data[node_name], d]

