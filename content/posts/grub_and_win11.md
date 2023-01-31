---
title: Linux和Win11双启动
date : 2022-12-11
draft: false
---




1. 查看硬盘分区
```shell
sudo fdisk -l
```
You should get a long return that includes something like this:
```
Device             Start        End   Sectors   Size Type
/dev/nvme0n1p1      2048    1050623   1048576   512M EFI System
/dev/nvme0n1p2   1050624  874729471 873678848 416.6G Linux filesystem
/dev/nvme0n1p3 874729472  874762239     32768    16M Microsoft reserved
/dev/nvme0n1p4 874762240 1000214527 125452288  59.8G Microsoft basic data
```
2. Get the UUID of the EFI partition sudo blkid /dev/nvme0n1p1 (replace nvme0n1p1 with the correct partition for you)
Return: dev/nvme0n1p1: UUID="3C26-6A4C" BLOCK_SIZE="512" TYPE="vfat" PARTLABEL="EFI System Partition" PARTUUID="3b64b43f-e7eb-4ac8-a32c-9af2edf64d0d"

3. 编辑 /etc/grub.d/40_custom ,加入如下内容：
注意把 3C26-6A4C 替换成你实际的 UUID:

```
menuentry 'Windows 11' {
    search --fs-uuid --no-floppy --set=root 3C26-6A4C
    chainloader (${root})/EFI/Microsoft/Boot/bootmgfw.efi
}
```

4. 更新grub

```shell
sudo update-grub
```

Reboot your computer reboot