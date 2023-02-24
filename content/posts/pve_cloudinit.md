---
title: "PVE Cloud-Init 使用"
date: 2023-02-01
draft: false
---



### 准备Cloud-Init 模板镜像

```shell

# 下载Ubuntu 22.04的Image镜像文件
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# create a new VM
qm create 9000 --memory 2048 --net0 virtio,bridge=vmbr0

# 有些文档写的是用：qm set 9000 --scsi0 local-lvm:0,import-from=bionic-server-cloudimg-amd64.img 方式导入，会报格式错误，需要使用importdisk导出才可以
# import the downloaded disk to local-lvm storage
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm

# finally attach the new disk to the VM as scsi drive
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# The next step is to configure a CDROM drive, used to pass the Cloud-Init data to the VM.
qm set 9000 --ide2 local-lvm:cloudinit

# We want to boot directly from the Cloud-Init image, so we set the bootdisk parameter to scsi0 and restrict BIOS to boot from disk only. This simply speeds up booting, because VM BIOS skips testing for a bootable CDROM.
qm set 9000 --boot c --bootdisk scsi0

# We also want to configure a serial console and use that as display. Many Cloud-Init images rely on that, because it is an requirement for OpenStack images.
#qm set 9000 --serial0 socket --vga serial0

# resize disk size to 50G
qm disk resize 9000 scsi0 50G

# 设置显示属性
qm set 9000 --vga std

# Copy your public ssh key to the proxmox server, so we can add this key to the cloud-init template:
[user_machine ~$] scp ~/.ssh/id_rsa.pub root@PROXMOX_NODE:/tmp

# Going back to proxmox server:
qm set 9000 --sshkey /tmp/id_rsa.pub

# 自定义用户，默认用户是ubuntu
qm set 9000 --ciuser tister

# Finally, it is usually a good idea to transform such VM into a template. You can create linked clones with them, so deployment from VM templates is much faster than creating a full clone (copy).
qm template 9000

```

### 构建VM镜像

```shell


# Finally clone the template to a new machine:
qm clone 9000 123 --name ubuntu2

# 设置IP
qm set 123 --ipconfig0 ip=192.168.8.32/24,gw=192.168.8.1

# boot vm
qm start 123

```

[参考文档1](https://pve.proxmox.com/wiki/Cloud-Init_Support)
[参考文档2](https://gameapp.club/post/2022-07-30-custom-cloud-init-for-pve/)