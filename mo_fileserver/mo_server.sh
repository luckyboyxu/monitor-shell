#!/bin/bash

#if [ "$PYTHONPATH" = '' ]; then
    #export PYTHONPATH='/usr/lib/python2.6/site-packages/pypi26x86_64'
#fi

export PYTHONPATH='/usr/lib/python2.6/site-packages/pypi26x86_64'

echo "`date +%Y%m%d-%T` mo_server.py start" >> ../var/log/mo_fileserver.log 2>&1
python2.6 mo_server.py >> ../var/log/mo_fileserver.log 2>&1
