#coding=utf-8

#�������ͣ���־·����server_id,Ĭ�ϲ�ѯ������ 
TASK  = [ ('fileServe', '/usr/local/file_server_2/var/log/FileServer.log', 'file_server2', 15000),
          ('fileServe', '/usr/local/file_server_2_500/var/log/FileServer.log', 'file_server2_500', 15000),
        ]
 
fs =  {
            'recv'       : 'recv request', 
            'send'       : 'dist success', 
            'write_ok'   : 'after write disk', 
            'write_fail' : 'writefile filesize error',
            'send_fail'  : 'failed after trying many times,the task is',
      }
          
web = {
            'recv' :  'ip:',
            'send' :  'dist ok',
      }
