---
title: "Pve下挂载Iscsi硬盘"
date: 2023-03-28
draft: false
---

### 硬盘挂载

```shell
$ sudo iscsiadm -m discovery -t sendtargets -p 192.168.8.10

$ sudo iscsiadm -m node –T iqn.2000-01.com.synology:DS-301.default-target.4f20e5e5897  \ 
-p 192.168.8.10 --op update -n node.startup -v automatic

$ sudo mount /dev/sdb1 /data

```

### 硬盘扩容

```shell
$ apt install lsscsi
$ lsscsi
[1:0:0:0]    cd/dvd  QEMU     QEMU DVD-ROM     2.5+  /dev/sr0
[2:0:0:0]    disk    QEMU     QEMU HARDDISK    2.5+  /dev/sda
[3:0:0:1]    disk    SYNOLOGY Storage          4.0   /dev/sdb
$ echo “—” >/sys/class/scsi_device/3\:0\:0\:1/device/rescan
$ lsblk
$ growpart /dev/sdb 1
$ fdisk -l
$ resize2fs /dev/sdb1
```

