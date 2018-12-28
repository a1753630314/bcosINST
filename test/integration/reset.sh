#!/bin/bash
dcoker network create bcos-ov
for i in $(ls peer*.bcos.bqj.cn.yaml)
do
    docker-compose -f $i down 
done 

echo "start clean the data"
for i in $(ls  -ld   data/node-*/data/* |grep drw|awk '{print $NF}')
do 
    rm -rf $i
done

for i in $(ls data/node-*/log/*.log)
do 
    rm $i
done

for i in $(ls data/node-*/log/*.log.*)
do 
    rm $i
done

for i in $(ls peer*.bcos.bqj.cn.yaml)
do
    docker-compose -f $i up -d 
done 
