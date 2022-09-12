#!/bin/bash

mkdir node-0/{data,log}
touch node-0/log/mongod.log

# docker network create -d bridge --subnet 180.48.0.0/16 --gateway 180.48.0.0 mongo

# docker run --rm -i --net mongo docker.io/amd64/mongo:6.0.1 cat /etc/mongod.conf.orig > ./node-0/mongod.conf 

chmod -R 777 node-0

# 不能使用账号密码，否则需要加证书
# -e MONGO_INITDB_ROOT_USERNAME="vmi" \
# -e MONGO_INITDB_ROOT_PASSWORD="vmi.@9_z!6" \

nerdctl run --name mongo-0 \
    --hostname mongo-0 \
    --net mongo \
    --ip 180.48.0.10 \
    -e TZ=Asia/Shanghai \
    -v $(pwd)/node-0/mongod.conf:/etc/mongo/mongod.conf \
    -v $(pwd)/node-0/data:/data/db \
    -v $(pwd)/node-0/log:/var/log/mongodb \
    -d \
    amd64/mongo:6.0.1 \
    -f /etc/mongo/mongod.conf

# 初始化络 (在集群中时host可以使用域名，为了便于调试，本处暂时使用IP)
# rs.initiate({_id: 'rs-vmi', members: [{_id: 0, host: '180.48.0.10'}]})