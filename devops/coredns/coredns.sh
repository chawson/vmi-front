#!/bin/bash

# 输出帮助
# docker run --rm -i coredns:1.9.4 -h 2>help
# 输出plugins
# docker run --rm -i docker.io/coredns/coredns:1.9.4 -plugins >plugins

# docker network create -d bridge --subnet 172.53.0.0/16 --gateway 172.53.0.1 coredns

nerdctl run --name coredns-0 \
    --hostname coredns-0 \
    --net coredns \
    --ip 172.53.0.10 \
    --restart always \
    -v $(pwd)/node-0/Corefile:/Corefile \
    -v $(pwd)/node-0/logs:/var/log/coredns \
    -v $(pwd)/node-0/hosts:/libire.hosts \
    -d \
    coredns/coredns:1.9.4 \
    -conf /Corefile \
    -log_dir /var/log/coredns \
