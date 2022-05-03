### Ingress Nginx Controller 部署 （社区版v1.2）
1. 环境
    - k8s: 1.23.6
    - kvm虚拟机 CentOs9-Stream * 3
      - Master: 192.168.122.100/24
      - Node1: 192.168.122.101/24
      - Node2: 192.168.122.102/24
    - kube-proxy Mode: ipvs
    - 网络插件：kube-flannel
    - ClusterCIDR: 10.244.0.0/16
    - ServiceCIDR: 10.96.0.0/12
    - [coredns manifest](../coredns/coredns.yaml)
1. 准备 Service
    - [tomcat & nginx](tomcat-nginx.yaml)
1. 安装Ingress Nginx(裸机版)
    1. 部署Deployment控制器
        ```sh
        kubectl apply -f baremetal-deploy.yaml
        ```
    1. 部署Ingress (HTTP)
        ```sh
        # 部署ingress
        kubectl apply -f ingress-http.yaml
        # 查看端口转发 (未指定nodePort, 观察到80:30344/TCP)
        kubectl get svc -n ingress-nginx
        ```
1. 物理机访问
    1. 添加hosts
        ```config
        192.168.122.100 nginx.libire.com
        192.168.122.100 tomcat.libire.com
        ```
    2. 浏览器域名访问
        ```txt
        # 能看到Nginx Welcome
        nginx.libire.com:30144 
        # 能看到Tomcat主页
        tomcat.libire.com：30144
        ```
