---
title: "使用Wireguard连接家用和办公网络"
date: 2023-03-22
draft: false
---


![Alt text](/images/home_wg.jpg)

### Wireguard安装

Linux

```shell
$ sudo add-apt-repository ppa:wireguard/wireguard
$ sudo apt-get update
$ sudo apt-get install wireguard
```

MacOS

```shell
$ brew install wireguard-tools
```

### 生成密钥

通过 wg 脚本生成公钥和私钥。私钥自用，公钥给到对端使用，跟ssh免密码登录类似

```shell
$ wg genkey | tee privatekey | wg pubkey > publickey
```
```
example privatekey - mNb7OIIXTdgW4khM7OFlzJ+UPs7lmcWHV7xjPgakMkQ=
example publickey - 0qRWfQ2ihXSgzUbmHXQ70xOxDd7sZlgjqGSPA9PFuHg=
```

[可选]为了防止未来可能存在的量子攻击，WireGuard 还额外引入了 PreSharedKey Layer 对所有数据包进行对称加密，preshared 密钥仅在client端配置

```shell
# wg genpsk > preshared
```


### 服务端配置

服务端只需配置[Interface]即可，[Peer]端的配置可由 wg set 命令完成添加

**注意** AllowedIPs 的子网掩码需要使用/32，不然会造成多条Peer间的路由冲突

```
################################
[Interface]
Address = 192.168.100.1/24  ##服务端IP
DNS = 1.1.1.1
PrivateKey = [ServerPrivateKey]  ##服务端私钥
ListenPort = 51820
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true   ## 通过wg命令更改的配置保存到配置文件

[Peer]
#Peer #PVE
PublicKey = [Peer#1PublicKey]
AllowedIPs = 192.168.100.5/32, 192.168.8.0/24


[Peer]
#Peer #mac book
PublicKey = [Peer#4PublicKey] 
AllowedIPs = 192.168.100.2/32
##################################

```

启动端口

```shell
wg-quick up wg0
```


### PVE配置

在 /etc/sysct.conf文件中，打开 ip forward
```
# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1
# Uncomment the next line to enable packet forwarding for IPv6
net.ipv6.conf.all.forwarding=1
```

Wireguard其实没有Server/Client的概念，是Peer To Peer模式，下面是一个Peer的配置示例

**注意** Address 的配置与Server端的AllowedIPs相同，但是掩码不一样，要特别注意

```
###################################
[Interface]
Address = 192.168.100.5/24   ### 客户端IP
PrivateKey = [PrivateKeyPeer#1]

[Peer]
PublicKey = [ServerPublicKey]
PresharedKey = [PresharedKey]
Endpoint = some.domain.com:51820
AllowedIPs = 192.168.100.0/24  ##允许100.x网段通过
# if you want to do split tunnel, add your allowed IPs
# for example if your home network is 192.168.1.0/24
# AllowedIPs = 192.168.1.0/24

# This is for if you're behind a NAT and
# want the connection to be kept alive.
PersistentKeepalive = 25
########################################
```

启动端口

```shell
wg-quick up wg0
```

在服务端Console下，执行命令添加Peer，注意掩码与Peer中的/24不一致，这里要用/32

```shell
wg set wg0 peer <client_pubkey> allowed-ips 192.168.100.5/32
```


把wg服务加入自启动

```shell
$ sudo systemctl enable wg-quick@wg0.service
$ sudo systemctl start wg-quick@wg0.service
```


### mac book配置


```
###################################
[Interface]
PrivateKey = [PrivateKeyPeer#1]
Address = 192.168.100.2/24
#DNS = 114.114.114.114
#MTU = 1420

[Peer]
PublicKey = [ServerPublicKey]
Endpoint = some.domain.com:51820
AllowedIPs = 192.168.100.0/24,192.168.8.0/24
PersistentKeepalive = 25
########################################
```

启动端口

```shell
wg-quick up wg0
```


### Home路由器配置
增加一条静态路由，类似下面的Linux语法
```shell
route add -net 192.168.100.0/24 gw 192.168.8.5
```


### 其它相关命令

查看路由表

```shell
# 查看系统路由表 linux
$ ip route show table main
$ ip route show table local

# 查看路由表 mac
$ netstat -nr

# 获取到特定 IP 的路由
$ ip route get 192.0.2.3
```

查看wg状态

```shell
sudo wg show  ## 等同于 wg

```

```
#########################################
peer: Peer #1
  endpoint: 192.168.2.1:50074
  allowed ips: 10.0.0.2/32
  latest handshake: 4 minutes, 16 seconds ago
  transfer: 57.58 KiB received, 113.32 KiB sent

peer: Peer #2
  endpoint: 99.203.28.43:36770
  allowed ips: 10.0.0.10/32
  latest handshake: 5 minutes, 30 seconds ago
  transfer: 92.98 KiB received, 495.89 KiB sent
##################################################
```

启用/停止wg0接口 

```shell
wg-quick up wg0
wg-quick down wg0
```

启用/停止 Wireguard服务  

```shell
$ sudo systemctl stop wg-quick@wg0.service
$ sudo systemctl start wg-quick@wg0.service
```

加入Peer

```shell
wg set wg0 peer <client_pubkey> allowed-ips 10.0.0.x/32
```

保存配置

```shell
wg-quick save wg0

```

生成QR Code

```
qrencode -t ansiutf8 < /etc/wireguard/wg0.conf
```