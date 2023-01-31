---
title: "Ubuntu_network"
date: 2022-09-19
draft: false
---

### Ubuntu下变更Mac

/etc/network/interfaces

```
auto wlan0
iface wlan0 inet dhcp
        hwaddress ether 9E:61:97:50:6E:04
```


### Ubuntu配置固定IP

```yaml
network:
    version: 2
    renderer: networkd
    ethernets:
        eth0:
            addresses:
                - 192.168.1.212/24
            nameservers:
                addresses: [8.8.8.8, 8.8.4.4]
            routes:
                - to: default
                  via: 192.168.1.2

```


### Ubuntu配置WIFI

记得提前安装 wpasupplicant 包

```shell
sudo apt install wpasupplicant
```

配置文件如下，比如：/etc/netplan/00-installer-config.yaml

```yaml
network:
  version: 2
  renderer: NetworkManager
  wifis:
    wlan0:
      dhcp4: no
      addresses:
        - 192.168.1.250/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 192.168.1.1
          - 114.114.114.114
      optional: true
      access-points:
          "26-1-3006":
               password: "xxxx"
      access-points:
          "HUAWEI_1B301":
               password: "xxxx"

```


```shell
$sudo netplan apply
```
