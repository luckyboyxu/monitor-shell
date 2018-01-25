#!/bin/bash

mon=`date +%Y%m`

mkdir var/log/log_$mon
mv var/log/*.log var/log/log_$mon

