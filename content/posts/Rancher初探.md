---
title: "Rancher初探"
tags: ["docker", "云原生"]
date: "2022-11-23"
draft: false
---

## Rancher概览

Rancher是一个开源的企业级容器管理平台。通过Rancher，企业再也不必自己使用一系列的开源软件去从头搭建容器服务平台。Rancher提供了在生产环境中使用的管理Docker和Kubernetes的全栈化容器部署与管理平台。

### 基础设施编排
Rancher可以使用任何公有云或者私有云的Linux主机资源。Linux主机可以是虚拟机，也可以是物理机。Rancher仅需要主机有CPU，内存，本地磁盘和网络资源。从Rancher的角度来说，一台云厂商提供的云主机和一台自己的物理机是一样的。

Rancher为运行容器化的应用实现了一层灵活的基础设施服务。Rancher的基础设施服务包括网络， 存储， 负载均衡， DNS和安全模块。Rancher的基础设施服务也是通过容器部署的，所以同样Rancher的基础设施服务可以运行在任何Linux主机上。

### 容器编排与调度
很多用户都会选择使用容器编排调度框架来运行容器化应用。Rancher包含了当前全部主流的编排调度引擎，例如Docker Swarm， Kubernetes， 和Mesos。同一个用户可以创建Swarm或者Kubernetes集群。并且可以使用原生的Swarm或者Kubernetes工具管理应用。

除了Swarm，Kubernetes和Mesos之外，Rancher还支持自己的Cattle容器编排调度引擎。Cattle被广泛用于编排Rancher自己的基础设施服务以及用于Swarm集群，Kubernetes集群和Mesos集群的配置，管理与升级。

### 应用商店
Rancher的用户可以在应用商店里一键部署由多个容器组成的应用。用户可以管理这个部署的应用，并且可以在这个应用有新的可用版本时进行自动化的升级。Rancher提供了一个由Rancher社区维护的应用商店，其中包括了一系列的流行应用。Rancher的用户也可以创建自己的私有应用商店。

### 企业级权限管理
Rancher支持灵活的插件式的用户认证。支持Active Directory，LDAP， Github等 认证方式。 Rancher支持在环境级别的基于角色的访问控制 (RBAC)，可以通过角色来配置某个用户或者用户组对开发环境或者生产环境的访问权限。

下图展示了Rancher的主要组件和功能：

![Rchaner overview](/images/rancher/rancher_overview_2.png)

## Rancher安装

我选择是在云上搭建一个小Rancher集群来测试，也给大家说一下省钱的小秘密，云上有一种竞价实例的模式，相对正常的预付费模式的云主机要便宜很多，非常适合这种学习性质的临时使用。这次我使用的就是腾讯云上的6台2core/4G的 CVM来进行本次测试。主机信息如下：


主机名 | 内部IP | 外部IP | 功能
---------|----------|---------|---------
 rancher_manager | 10.206.0.13 | xxxx | Rancher主控节点
 worker1 | 10.206.0.6 | xxx | ETCD&Control Plane&Worker 
 worker2 | 10.206.0.8 | xxx | ETCD&Control Plane&Worker 
 worker3 | 10.206.0.11 | xxx | ETCD&Control Plane&Worker 
 worker4 | 10.206.0.16 | xxx | Worker
 worker5 | 10.206.0.2 | xxx | Worker

通过 hostnamectl 变更主机名称，例如：
```shell
sudo hostnamectl hostname --static worker1
```

**特别注意** 
需要确认 /etc/hosts 文件中，有主机名与内部IP的对应记录，如：
```
10.206.0.6  worker1
```
一定注意这点，我就被这个坑了好久，一直发现etcd连接不上，原来它一直LISTEN在 127.0.0.1 localhost上。可以通过netstat -lntp 查看一下 2379和2380两个端口，是不是LISTEN在 0.0.0.0 地址。

### Docker运行环境准备

Rancher默认都通过Docker运行，所以安装所有的节点前，都必须先安装最新版本的Docker，Linux发行版带的Docker可能不符合要求，建议通过Rancher提供的脚本安装:

```shell
curl https://releases.rancher.com/install-docker/20.10.sh | sh
```

### Rancher主控安装

通过Docker安装Rancher主控节点

```shell
sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/server:stable
```
上述命令运行结束后，会拉起Rancher主控，系统会侦听在80和443端口，可以通过netstat -lntp | grep 443 查看是否正常运行。确认正常运行后，就可以在浏览器中打开Rancher的控制面板，Rancher安装过程中，会生成一个随机密码，具体密码可以通过下面的命令得到:
```shell
docker logs e01aa22dc6fc  2>&1 | grep "Bootstrap Password:"
```
其中『e01aa22dc6fc』是实际Rancher主控在当前机器运行的镜像ID，需要通过 docker ps 查看并更新。同时，通过默认密码首次登录后，记得更新你的密码。

至此，一个最小化的Rancher主控环境就安装完毕，当然这个只是实验环境的Rancher主控，它不具备高可用，不用直接用于生产。下面我们通过它进行kubernetes集群的创建并注册。

### 配置国内仓库
[配置国内仓库](https://docs.rancher.cn/docs/rancher2/best-practices/use-in-china/_index/)
设置默认镜像仓库
从 UI 导航到Settings，然后编辑system-default-registry，Value 设置为registry.cn-hangzhou.aliyuncs.com

### kubernetes集群创建

首先在所有的集群节点上通过上面的脚本安装新版本的docker运行环境。接下来所有的工作都是通过Rancher主控面板进行了。
1. 在「首页」点击「创建」，然后选择「自定义」即可。
![cluser create](/images/rancher/cluster_create.png)
2. 在「集群」创建页中，填写集群的名称，比如：cluster1, **特别注意：** Kubernetes版本使用1.24版本创建集群一直不成功，不知道什么原因，最终使用v1.23.12版本成功,其实选项没有特别需要，保持默认即可。
![Alt text](/images/rancher/cluster_create_2.png)

3. 接下来添加集群主机，主机我分了两类，一类是带Etcd和control Panel的worker，另一类仅仅是Worker，所以注意一下「主机选项」这里的选择。
![Alt text](/images/rancher/cluter_create_3.png)

根据提示，把相应命令拷贝在目标主机的终端执行，即可完成主机添加。建议先完成三个带Control Panel主机的添加，然后再添加Worker节点。

完成上述步骤后，返回首页，即可看到新建的集群了。集群的创建过程需要拉取镜像和注册，需要一定时间。待集群状态这里变成「Active」表示创建成功，如下图：

![Alt text](/images/rancher/cluster_create_3.png)

### 其它事项

有时发现注册失败，要重新配置，重新配置前，最好使用下述命令清空一下原配置

```shell
sudo docker stop $(sudo docker ps -aq)
sudo docker system prune -f
sudo docker volume rm $(sudo docker volume ls -q)
sudo docker image rm $(sudo docker image ls -q) -f
sudo rm -rf /etc/ceph \
       /etc/cni \
       /etc/kubernetes \
       /opt/cni \
       /opt/rke \
       /run/secrets/kubernetes.io \
       /run/calico \
       /run/flannel \
       /var/lib/calico \
       /var/lib/etcd \
       /var/lib/cni \
       /var/lib/kubelet \
       /var/lib/rancher/rke/log \
       /var/log/containers \
       /var/log/pods \
       /var/run/calico
```
如果提示 Device Busy ,用下述命令umount一下
```shell
umount $(df -HT | grep '/var/lib/kubelet/pods' | awk '{print $7}')
```
### 部署Helloworld

参考手册，部署一个helloworld应用 [部署带有 Ingress 的工作负载](https://docs.ranchermanager.rancher.io/zh/getting-started/quick-start-guides/deploy-workloads/workload-ingress)



https://ranchermanager.docs.rancher.com/pages-for-subheaders/rancher-on-a-single-node-with-docker

