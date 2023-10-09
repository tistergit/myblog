---
title: "Docker空间不足的故障处理"
date: 2023-04-17
draft: false
---

### 开篇

Docker迁移默认的/var/lib/docker目录

1. 停止docker服务

```shell
systemctl stop docker
```

2. 创建docker新目录

```
mkdir -p /data/docker/lib
```

3. 安装迁移软件包

```
yum install rsync -y
```

4. 开始迁移

```
rsync -avzP /var/lib/docker /data/docker/lib/
```
5. 修改docker配置文件docker.service
   
   ```
   vi /lib/systemd/system/docker.service
   ```
   在ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock后添加 
   **--data-root=/data/docker/lib/docker**
   网上很多文章写的是添加： --graph=/data/docker/lib/docker  ，这个是错的，会造成docker启动失败
6. 重启docker
```
systemctl daemon-reload
systemctl restart docker

```
7. 确认docker没有问题，删除原目录

```
rm -rf /var/lib/docker
```