---
title: "GPU容器化使用记录"
tags: ["docker", "gpu"]
date: "2023-5-17"
draft: false
---

## GPU容器化使用记录

https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installation-guide



curl -s -L https://nvidia.github.io/libnvidia-container/centos8/libnvidia-container.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

yum list -y