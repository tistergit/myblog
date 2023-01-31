---
title: 使用ssh远程控制家里的电脑
date: 2022-09-18
draft: false
---

## 使用ssh远程控制家里的电脑

### 背景
家里有1台N年前的笔记本，给二手收也没几个钱，装了个Linux系统放在那里，偶尔周末玩一下。同时也购买了1台最小化的云主机，腾讯云新出的AMD CPU云主机，非常合算，在搞活动的时候一下买了4年。接下来告诉大家怎么通过云主机转发控制家里这台旧笔记本。
主角当然是ssh，通过它的远程端口转发，把云主机的2222端口转发到家里笔记本的22端口上，这样就可以在任意其它可上网的地方，远程访问到家里这台机器了。远程转发命令非常简单，如下：ssh -R 2222:localhost:22 root@www.tister.cn，这个命令会在www.tister.cn 这台云主机上开一个2222端口，转发到家里的笔记本的22端口上。问题是这个通道不是一直用，中间网络超时或断开的时候，这个转发通道就断了，不能重连。这里需要另外一个工具：autossh，它会侦测转发通道是否断开，如果断开就重连，保证了转发通道一直可用。下面说一下配置步骤：

### 安装autossh

```shell
yum -y install autossh
```

### 配置ssh免密码登录
首先通过ssh-keygen生成一个ssh公钥，之后利用ssh-copy-id命令把公钥拷贝到云主机上。

```shell
ssh-copy-id root@www.tister.cn
```
拷贝成功后，使用ssh root@www.tister.cn 测试一下是否可以免密码登录。

### 写一个systemd的开机自启动脚本
使用vim建立和编辑 /etc/systemd/system/remote-autossh.service 文件，内容如下：

```shell
[Unit]
Description=AutoSSH service for remote tunnel
After=network-online.target

[Service]
User=root
ExecStart=/usr/bin/autossh -M 20001 -N -o "PubkeyAuthentication=yes" -o "StrictHostKeyChecking=false" -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R 2222:localhost:22 root@www.tister.cn

[Install]
WantedBy=multi-user.target
```
### 配置开机自启动

```shell
systemctl daemon-reload
systemctl enable remote-autossh.service
systemctl start remote-autossh.service
```

### 验证
登录云主机，通过netstat -lnt 查看2222端口是不是存在。可以通过 ssh root@localhost -p 2222 ,输出家里笔记本的root密码，就可以登录家里的主机了。