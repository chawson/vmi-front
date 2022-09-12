#!/bin/bash

# sudo chmod +s $(which nerdctl)

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

# cluster-preferred-endpoint-type hostname
# cluster-announce-hostname redis-${port}
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
        nerdctl run -e TZ=Asia/Shanghai \
        --hostname redis-${port} \
        --name redis-${port} \
        -v $workerDir/data:/data \
        -v $workerDir/conf/redis.conf:/etc/redis/redis.conf \
        --net redis \
        --ip 172.38.0.1${port} \
        -d \
        redis:7.0.4-alpine redis-server /etc/redis/redis.conf 
    done
}



# 进入某个节点执行
# nerdctl run --rm -it --network redis redis:7.0.4-alpine redis-cli -h redis-0 --cluster create 172.38.0.1{0..5}:6379  --cluster-replicas 1
# 下面的这种使用域名的方式暂不支持，redis集群暂不支持dns解析
# nerdctl run --rm -it --network redis redis:7.0.4-alpine redis-cli --cluster create redis-{0..5}:6379 --cluster-replicas 1 -a '123456'
# makeSetting

startRedisCluster

# 执行redis-cli
# docker run -it --network redis --rm redis:7.0.4 redis-cli -h 172.38.0.10 -p 6379 -a "123456" -c

# 启动redis
# docker ps -a --filter name="redis-.+" --filter status=exited  --format '{{json .Names}}' | xargs docker start

# 停止redis 
# docker ps --filter name="redis-.+" --filter status=running --format '{{json .Names}}' | xargs docker stop
# alias redis-stop="docker ps --filter name='redis-.+' --filter status=running --format '{{json .Names}}' | xargs docker stop"

# redis cluster keyslot 用于测试 {名称插槽}的hash, 用于实现指定集群机器
# set my{testing} a 

# nerdctl ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | awk '{if($2 ~ /^redis-.+/ && $3=="Up") print $1}' | xargs nerdctl stop
# nerdctl ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | awk '{if($2 ~ /^redis-.+/ && $3=="Exited") print $1}' | xargs nerdctl start