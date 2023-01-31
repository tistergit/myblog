---
title: Ubuntu下配置Wireguard实现家庭网络与云网络互通
date : 2022-12-11
draft: false
---


前言：前几天花了1500元左右在PDD DIY了一台电脑，配置如下：双E5 CPU + 128G内存 + geforce gtx 1050显卡，在家玩玩极品飞车感觉很爽。不过如果只用来玩游戏就有点太浪费了，所以在它上面安装了个PVE，用来做云主机，后续搞什么东西就不用在云上买CVM了，现在的问题是，怎么把它连到网上，让外网可访问，之前我一般都是用ssh打隧道，这次尝试一下用WireGuard，感觉比ssh用起来更爽一些。这里记录一下安装过程。

WireGuard其实是一个Peer To Peer VPN软件，常用网络模型如图![](/images/site-to-site-complex.svg)



### 软件安装

带外网IP的云主机一台，VPC: 10.206.0.4/20 ,使用Ubuntu22.04系统,家里的电脑安装的是pve，内网网段：192.168.1.1/25 ，通过下面的命令安装Wireguard
```
sudo apt update && sudo apt install wireguard
``` 

**注意** wg-quick工具会改写 wg0.conf 文件，所以在变更配置前，提前使用：wg-quick down wg0 命令，把接口down掉

wg和wg-quick命令行工具可帮助您配置和管理WireGuard接口，WireGuard接口是虚拟网卡。WireGuard VPN网络中的每个设备都需要具有私钥和公钥。

我们可以使用wiregurad的工具wg genkey和wg pubkey在/etc/wireguard/目录中生成私钥/etc/wireguard/privatekey和公钥/etc/wireguard/publickey。

以下命令将使用wg genkey和wg pubkey，tee命令以及管道同时生成私钥和公钥并存储在/etc/wireguard/目录
```shell
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
```

### 配置WireGuard服务端

```
vi /etc/wireguard/wg0.conf
```
注意Address、PrivateKey和eth0，根据实际情况进行变更

``` /etc/wg0.conf
[Interface]
Address = 192.168.100.1/24  ## vpn本地地址
SaveConfig = true
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```
接口的命名可以是任何你喜欢的名称，但是建议使用诸如wg0或wgvpn0之类的名称。可以让我们能快速分清是物理接口还是虚拟接口即可。

这里说明一下/etc/wireguard/wg0.conf配置文件定义接口的每个字段含义。

#### Address 
wg0接口的IP v4或IP v6的地址。请使用保留给私有网络范围内的IP地址，比如10.0.0.0/8、172.16.0.0/12或192.168.0.0/16。

#### ListenPort 
是接口监听的端口。PrivateKey 由wg genkey命令生成的私钥。你可以使用sudo cat /etc/wireguard/privatekey命令要查看私钥文件的内容。

#### SaveConfig 
设置为true时，当关闭接口时将当前配置将保存到配置文件中。

#### PostUp PostDown
在启动接口之前、后执行的命令或脚本

在此示例中，在PostUp钩子启用iptables伪装。这允许流量离开服务器，使VPN客户端可以访问互联网。

请记得使用您可访问网络的接口名称替换-A POSTROUTING后面的eth0。您可以通过以下ip命令方式轻松找到可访问网络的接口。
```
ip -o -4 route show to default | awk '{print $5}'
```
为了保证私钥的安全，请将wg0.conf和privatekey文件对普通用户不可读。运行chmod命令sudo chmod 600 /etc/wireguard/{privatekey,wg0.conf}

```
sudo chmod 600 /etc/wireguard/{privatekey,wg0.conf}
```
### 启用Wireguard接口

完成以上步骤后，我们可以通过wg-quick启动wireguard服务器。这在wireguard中就是将接口状态设置为开启，运行wg-quick up命令将启用wg0接口。

```
sudo wg-quick up wg0
```
要检查接口状态和配置，请运行wg show命令。因为wg0是一个虚拟网卡，因此您也可以运行ip a show wg0来验证wg0接口状态。
```
sudo wg show wg0
ip a show wg0
```

wireguard作为内核模块运行，默认情况wireguard会自动启动，但接口wg0虚拟网卡不会自动启动。

你可以通过systemctl命令将wg0设置为自动启动。要在启动时启用WireGuard的wg0接口。请运行sudo systemctl enable wg-quick@wg0命令。



### 配置客户端

设置Linux和macOS客户端的过程几乎与服务器相同，这是因为两端之间是对等。

首先使用wiregurad的工具wg genkey和wg pubkey生成公钥和私钥并保存在/etc/wireguard/目录。

```shell
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
```
使用你喜欢的文本编辑器创建配置文件/etc/wireguard/wg0.conf，在本教程中我们将使用vim创建文件。

```
sudo vim /etc/wireguard/wg0.conf
```

```
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY #客户端生成的私钥
Address = 10.0.0.2/24


[Peer]
PublicKey = SERVER_PUBLIC_KEY  #服务器端生成的公钥
Endpoint = SERVER_IP_ADDRESS:51820
AllowedIPs = 192.168.100.0/24
PersistentKeepalive = 25
```

#### Interface
PrivateKey 客户端生成的私有密钥，可以使用cat命令sudo cat /etc/wireguard/privatekey查看客户端计算机的私有密钥文件的内容。

Address wg0接口的IPv4或IP v6地址。

#### Peer
PublicKey 您要连接的对等方的公钥。也就是服务器端的/etc/wireguard/publickey文件内容。

Endpoint 您要连接的对等方的IP地址或主机名，后跟冒号，然后是远程对等方监听的端口号，默认是51820。注意：这个IP地址是公网可访问的IP地址。

#### AllowedIPs 
是使用逗号分隔的IPv4或IP v6地址列表，如果数据包与IP列表匹配，这些数据包将走wireguard通道。
如果使用0.0.0.0/0表示将所有流量都转发到wireguard服务器端。如果您需要配置其他客户端，只需重复相同的步骤即可。

### 将客户端添加到服务器

最后一步是将客户端的公钥和IP地址添加到对等方，也就是服务器端口。要将客户端添加到服务器，非常简单。

你只需要在Ubuntu 20.04服务器运行命令sudo wg set wg0 peer CLIENT_PUBLIC_KEY allowed-ips 10.0.0.2。

请使用在客户端计算机生成的公钥替换CLIENT_PUBLIC_KEY，可以通过sudo cat /etc/wireguard/publickey命令查看客户端的公钥。

Windows用户可以从WireGuard应用程序复制公钥。

```
sudo wg set wg0 peer CLIENT_PUBLIC_KEY allowed-ips 10.0.0.2
```

Linux和macOS客户端运行命令sudo wg-quick up wg0启用客户端wg0接口。

```
sudo wg-quick up wg0
```
现在，您应该已连接到Ubuntu 20.04服务器，并且来自客户端计算机的流量应通过该服务器。 您可以运行sudo wg命令检查连接。

如果一切正常，你应该看到wg0接口，transfer和received的数据大小。

您也可以打开浏览器，搜索what is my ip，然后您应该会看到您的Ubuntu服务器IP地址。

要停止使用wiregurad，请关闭wg0接口，运行命令sudo wg-quick down wg0。

```
sudo wg
sudo wg-quick down wg0
```

### 参考链接

https://www.myfreax.com/how-to-set-up-wireguard-vpn-on-ubuntu-20-04/


https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-20-04


https://zhangguanzhang.github.io/2020/08/05/wireguard-for-personal/#/qos


https://www.cnblogs.com/milton/p/15339908.html


https://argoproj.github.io/argo-workflows/quick-start/


https://www.procustodibus.com/blog/2020/12/wireguard-site-to-site-config/
