---
title: "Kubernetes集群搭建"
date: 2022-09-19
draft: false
---
## Kubernetes示意图
![业务信息示例](/images/k8s-cluster-setup-ubuntu-20-04-lts-server-1024x608.png)

## 组件说明
- 控制面
  
| 组件名 | 功能 |
| --- | --- |
| kube-apiserver | API请求 |
| kube-controller-manager | 资源编排 |
| etcd | 集群数据存储 |
| kube-scheduler | 节点调度 |

- Node组件

| 组件名 | 功能 |
| --- | --- |
| kubelet  | xxx |
| kube-proxy | xx |

- 开放接口
  - CRI（Container Runtime Interface）：容器运行时接口，提供计算资源
  - CNI（Container Network Interface）：容器网络接口，提供网络资源
  - CSI（Container Storage Interface）：容器存储接口，提供存储资源

### 系统准备
```shell
# 允许 iptables 检查桥接流量
sudo tee /etc/modules-load.d/containerd.conf << EOF
overlay
br_netfilter
EOF

sudo tee /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

# 使设置生效
sudo modprobe overlay
sudo modprobe br_netfilter
sudo sysctl --system

# 禁用虚拟内存
sudo swapoff -a

# 永久禁用虚拟内存，需要注释 /etc/fstab 中的下述行

# /swap.img      none    swap    sw      0       0
```

### 安装容器运行时

- 安装 containerd
```shell
sudo curl -Lo /etc/apt/trusted.gpg.d/docker-ce.asc http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg
echo "deb http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y containerd.io

# 配置容器运行时
sudo tee /etc/containerd/config.toml << EOF
version = 2
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.6"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
    runtime_type = "io.containerd.runc.v2"
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
    endpoint = ["https://hub-mirror.c.163.com"]
EOF

sudo systemctl restart containerd

```

- 安装 kubeadm
```shell
sudo curl -Lo /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg
echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubeadm kubectl kubelet

##
# 添加自动填充
echo 'source <(kubectl completion bash)' >>~/.bashrc

# 配置 crictl
sudo tee /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF

```
- 创建集群
```shell
sudo kubeadm init \
--image-repository registry.aliyuncs.com/google_containers \
--apiserver-advertise-address 192.168.8.10 \
--pod-network-cidr=192.168.0.0/24 --v=5


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

#
chmod a+r /etc/kubernetes/admin.conf

export https_proxy=http://192.168.8.250:7890
export http_proxy=http://192.168.8.250:7890
export no_proxy=localhost,127.0.0.1,192.168.8.0/24

```
安装上述后，

- 安装网络组件
```shell
kubectl create -f https://projectcalico.docs.tigera.io/manifests/calico.yaml

```

### worker节点加入

在kube主控节点上执行如下命令生成 join 命令行，然后在worker节点上执行，即可完成Worker加入集群的操作

```shell
kubeadm token create --print-join-command
```

```shell
sudo hostnamectl set-hostname worker41
```

```shell
mkdir -p /etc/systemd/system/containerd.service.d

cat > /etc/systemd/system/containerd.service.d/http_proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://192.168.8.250:7890"
Environment="HTTPS_PROXY=http://192.168.8.250:7890"
Environment="NO_PROXY=192.168.8.0/24"
EOF


sudo systemctl daemon-reload
sudo systemctl restart containerd

```