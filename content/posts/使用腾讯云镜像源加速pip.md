---
title: "使用腾讯云镜像源加速pip"
date: 2023-05-18
draft: false
---

## 使用腾讯云镜像源加速pip

### 临时使用
运行以下命令以使用腾讯云pypi软件源：

```shell
pip install -i https://mirrors.cloud.tencent.com/pypi/simple <some-package>
```

注意：必须加上路径中的simple

### 设为默认
升级 pip 到最新的版本 (>=10.0.0) 后进行配置：

```shell
pip install pip -U
pip config set global.index-url https://mirrors.cloud.tencent.com/pypi/simple
```

您也可以临时使用本镜像来升级 pip：
```shell
pip install -i https://mirrors.cloud.tencent.com/pypi/simple --upgrade pip
```