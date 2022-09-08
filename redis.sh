#!/bin/bash


#docker network create --driver bridge --subnet 192.162.0.0/16 --gateway 192.162.0.1 cluster-net
#docker run --name vmi-redis -d redis:7.0.4 redis-server

# 1. 创建子网
# docker network create--driver bridge --subnet 172.38.0.0/16 --gateway 172.38.0.1 cluster-net

# 2. 生成配置文件
makeSetting() {
    for port in {0..5};
    do 
        workerDir=$(pwd)/node-${port}
        mkdir -p $workerDir/{conf,data}
        cat > $workerDir/conf/redis.conf <<-EOF
port 6379
bind 0.0.0.0
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-announce-ip 172.38.0.1${port}
cluster-announce-port 6379
cluster-announce-bus-port 16379
appendonly yes
masterauth "123456"
requirepass "123456"
EOF
    done
}

startRedisCluster() {
    for port in {0..5};
    do
        workerDir=$(pwd)/node-${port}
        docker run -p 637${port}:6379 -p 1637${port}:16379 \
        --name redis-${port} \
        -v $workerDir/data:/data \
        -v $workerDir/conf/redis.conf:/etc/redis/redis.conf \
        -d \
        --net redis \
        --ip 172.38.0.1${port} \
        redis:7.0.4 redis-server /etc/redis/redis.conf 
    done
}

# 进入某个节点执行
# redis-cli --cluster create 172.38.0.1{0..5}:6379  --cluster-replicas 1

makeSetting

# startRedisCluster

# 执行docker-cli
# docker run -it --network redis --rm redis:7.0.4 redis-cli -h 172.38.0.10 -p 6379 -a "123456" -c

# 启动redis
# docker ps -a --filter name="redis-4.+" --filter status=exited  --format '{{json .Names}}' | xargs docker start

# 停止 redis 
# docker ps --filter name="redis-4.+" --filter status=running --format '{{json .Names}}' | xargs docker stop
# alias redis-stop="docker ps --filter name='redis-4.+' --filter status=running --format '{{json .Names}}' | xargs docker stop"

# redis cluster keyslot 用于测试 {名称插槽}的hash, 用于实现指定集群机器
# set my{testing} a 