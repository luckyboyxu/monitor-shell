#!/bin/bash
MyPath=$(cd $(dirname $0)/..; pwd)
cd $MyPath

. conf/globle.cfg
. bin/functions.sh

mydate=$(date "+%Y-%m-%d %T")
basepath=$(cd `dirname $0`; pwd)
data=` sh $basepath/summary 2>/dev/null | awk '{
    if($0 ~ /^#/){
        category=$0;gsub(/#/,"",category);gsub(/^ *| *$/,"",category);catearr[category]=category;
    }else if($0 ~ /\|/){
        split($0,d,"|");key=d[1];value=d[2];gsub(/^ *| *$/,"",key);gsub(/^ *| *$/,"",value);summary[category,key]=value;
    }else{
        line=$0;gsub(/\n/,"\\n",line);gsub(/\t/,"\\t",line);
        summary[category,"detail"] = summary[category,"detail"]""line"\\\\n";
    }
}END{
    output = "{";
    for(i in catearr){
        if(ni!=0){output = output",";}
        output = output"\""i"\":{";
        nj=0;
        for(j in summary){
            split(j,jd,SUBSEP);
            if(i==jd[1]){
                if(nj!=0){output = output",";}
                output = output"\""jd[2]"\":\""summary[j]"\"";
                nj++;
            }
        }
        output = output"}";
        ni++;
    }
    output = output"}";
    print output;
}'`

curl -s -d "$data" "http://ops.500wan.com/index.php?r=api/reportHostInfo" > /dev/null 2>&1
echo "{'hostname':'$hostname','status':0,'date':'$mydate','msg':'no thing'}"