---
title: "搭建自己的ChatGPT系列4：本地推理与快速部署"
date: 2023-04-12
draft: true
---

### 下载Docker镜像

#### 安装Docker-ce

```shell
git config --global url.git@git.woa.com:.insteadof https://git.woa.com/
```

#### 配置docker代理
在 /etc/docker/daemon.json 中写入如下内容（如果文件不存在请新建该文件）

```json
{
  "registry-mirrors": [
    "https://dockerhub.woa.com"
  ]
}
```
之后重新启动服务

```shell
systemctl daemon-reload
systemctl restart docker
```

pull 镜像

```
docker pull mirrors.tencent.com/rms/llama_finetune:v1
```

### 下载原LLaMA模型权重文件

### 转换模型权重到HF格式

### 准备数据集

### Fine-tune模型

### 模型推理