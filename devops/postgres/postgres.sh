#!/bin/bash

# docker network create -d bridge --subnet 176.42.0.0/16 --gateway 176.42.0.1 postgres

# 1. 获取基础配置
# docker run -i --rm amd64/postgres:14.5-alpine cat /usr/local/share/postgresql/postgresql.conf.sample > postgres.conf

# 注意： 某些 alpine实际上不支持 TZ, 需要使用Dockerfile做镜像安装 tzdata
# 本镜像中 TZ有效

nerdctl run --name postgres-0 \
    --hostname postgres-0 \
    --net postgres \
    --ip 176.42.0.10 \
    -e TZ=Asia/Shanghai \
    -e POSTGRES_HOST_AUTH_METHOD="scram-sha-256" \
    -e POSTGRES_PASSWORD="vmi.@9_z!6" \
    -e POSTGRES_USER="vmi" \
    -e PGDATA=/var/lib/postgresql/data \
    -v $(pwd)/node-0/postgres.conf:/etc/postgresql/postgresql.conf \
    -v $(pwd)/node-0/data:/var/lib/postgresql/data \
    -d \
    amd64/postgres:14.5-alpine \
    -c 'config_file=/etc/postgresql/postgresql.conf'