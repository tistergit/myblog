---
title: "Openwrt下配置Wireguard"
date: 2023-02-04
draft: false
---



### Wireguard软件安装

```shell
opkg update
opkg install luci-i18n-wireguard-zh-cn luci-app-wireguard kmod-wireguard luci-proto-wireguard wireguard-tools

## reboot router 
reboot

```


