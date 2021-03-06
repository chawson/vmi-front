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
    - [coredns manifest](../coredns)
1. 准备 Service
    - [tomcat & nginx](tomcat-nginx.yaml)
1. 安装Ingress Nginx(裸机版)
    1. 准备镜像
        ```sh
        GCR_PREFIX=k8s.gcr.io/ingress-nginx
        MIRROR_LOCATION=registry.cn-hangzhou.aliyuncs.com/google_containers
        
        # controller镜像
        CONTROLLER_IMAGE=$MIRROR_LOCATION/nginx-ingress-controller:v1.2.0
        # certgen镜像
        WEBHOOK_IMAGE=$MIRROR_LOCATION/kube-webhook-certgen:v1.1.1
        
        docker pull $CONTROLLER_IMAGE
        docker tag $CONTROLLER_IMAGE $GCR_PREFIX/controller:v1.2.0
        docker rmi $CONTROLLER_IMAGE
        
        docker pull $WEBHOOK_IMAGE
        docker tag $WEBHOOK_IMAGE $GCR_PREFIX/kube-webhook-certgen:v1.1.1
        docker rmi $WEBHOOK_IMAGE
        ```
    1. 部署Deployment控制器
        ```sh
        kubectl apply -f baremetal-deploy.yaml
        ```
    1. 自签tls证书
        ```sh
        # 申请自签证书
        openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/C=CN/ST=BJ/L=BJ/O=nginx/CN=libire.com"
        # 创建k8s证书
        kubectl create secret tls ingress-https-secret --key tls.key --cert tls.crt
        ```
    1. 部署Ingress (HTTPS)
        ```sh
        # 部署ingress
        kubectl apply -f ingress-https.yaml
        # 查看端口转发 (未指定nodePort, 观察到80:30144/TCP,443:31786/TCP)
        kubectl get svc -n ingress-nginx
        ```
1. 物理机访问
    1. 添加hosts
        ```config
        192.168.122.100 nginx.libire.com
        192.168.122.100 tomcat.libire.com
        ```
    1. 浏览器域名访问
        ```txt
        # 能看到Nginx Welcome
        http://nginx.libire.com:30144
        https://nginx.libire.com:31786
        # 能看到Tomcat主页
        http://tomcat.libire.com：30144
        https://tomcat.libire.com:31786
        ```
