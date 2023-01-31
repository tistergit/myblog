---
title: "vscode本地容器开发篇"
tags: ["dev", "docker"]
date: "2022-11-14"
draft: false
---

## 前言

大家肯定有遇过需要在别的电脑重新安装开发环境，可能搞完半天什么代码都没写，环境还没搞好；又或是项目成员的开发环境设定不一致造成一些莫名其妙的问题

如果能将开发环境设定纳入版本控管，让后续加入项目的成员可以马上开发，而不用再费心安装开发环境，岂不是很棒！

VSCode 的Remote - Containers 是基于Docker 运行，下方图示可以看到程式码是通过Volume 挂载到Container，Container Port 映射到本地Port，执行命令、程序运行、Debugger 皆是在Container 中完成。如下图所示：

![vsc container示意图](/images/architecture-containers.png)

容器开发有两种模式：

- 基于本地容器的模式(本文描述的方式)

  要求本地安装Docker环境，Docker会把开发使用的镜像Pull到本地来运行，有点类似Python env模式；

- 基于远程容器的模式
  
  Docker也运行于远程开发机上，本地机器通过ssh远程连接到目标开发机的容器中进行开发，有点类似瘦客户端模式，本地只要求安装VSC以及相关插件即可；


## 环境准备

客户机：我用的是Mac M1机器，提前安装了Docker Desktop 和 vsc最新版本。vsc需要安装Dev Containers ：容器开发插件。安装方式：快捷键（⇧⌘X）打开扩展面板，搜索Dev Containers，点击安装即可。如下图：
![vsc Dev Containers插件安装](/images/vsc_dev_container_install.jpg)

### 免密钥登录

- Mac客户机
  
  通过下述命令生成密钥对
  ```shell 
  $ ssh-keygen  // 生成密钥对
  $ ssh-copy-id root@xxx.xxx.xxx.xxx
  ```
- Ubuntu服务器(一定要用Root账号)
  配置sshd服务，让其可以实现Root用户通过私钥登录，编辑 /etc/ssh/sshd_config 文件，加入： 
  ```
  PermitRootLogin without-password 
  ```

**注意：** 一定要用Root账号才可以，因为Dev Containers插件要通过docker images查看Linux下所有的镜像，这个命令必须是Root账户才能执行，所以这里必须使用Root账号。又由于Ubuntu默认是不允许Root账号远程登录的，这里要多一些步骤才行。

### Ubuntu服务器配置

1. 安装Docker
  
  根据Docker官网上的操作流程安装Docker，这里请注意尽量按这个文档来安装Docker，不要通过apt install docker安装Ubuntu上默认的版本，那个版本可能有问题，造成不必要的麻烦
  [Ubuntu下安装Docker](https://docs.docker.com/engine/install/ubuntu/)

### VSC配置



#### 开发镜像制作

开发镜像根据实际开发的开发语言、依赖库不同而各异，建议自己通过编写Dockerfile的方式来制作，当然也可以在网上找别人已经制作好的镜像直接使用，或在此基础上进行更新。

- 获取已有镜像：

```
$ docker pull fatindeed/vscode-remote-go
$ docker run -d -P --name go-dev --mount type=bind,source=/home/ubuntu/source,target=/app/source fatindeed/vscode-remote-go
```

- 通过编写Dockerfile构建一个镜像：

比如开发环境是基于python3和flask框架的一个Web项目，可以通过下述方式生成需要使用的镜像

Dockerfile 文件：
```
# syntax=docker/dockerfile:1

FROM python:3.9.2

WORKDIR python-docker

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY . .

## sleep infinity  终端睡眠无限长事件
CMD ["sleep" "infinity"]
```

docker-compose.yml 文件：
```yml
version: '3'

services:
  app:
    # Using a Dockerfile is optional, but included for completeness.
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      # This is where VS Code should expect to find your project's source code and the value of "workspaceFolder" in .devcontainer/devcontainer.json
      - /home/ubuntu/source:/workspace

    # Overrides default command so things don't shut down after the process ends.
    command: sleep infinity
```

requirements.txt 文件：
```
click==8.0.3
Flask==2.0.2
itsdangerous==2.0.1
Jinja2==3.0.2
MarkupSafe==2.0.1
Werkzeug==2.0.2
```

app.py 文件：
```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_geek():
    return '<h1>Hello from Flask & Docker</h2>'


if __name__ == "__main__":
    app.run(debug=True)
```

```shell
$ docker compose build --pull //构建镜像
$ docker compose up -d //启动镜像
```

验证一下镜像是否正常生成和正常运行：
```python
$ docker images  // 查看镜像是否正常生成
$ docker ps  // 查看镜像是否正常运行
```


#### VSC上会用

先通过remote ssh连接上Linux服务器

![vsc remote ssh配置](/images/vsc_remote_ssh.png)

根据提示进行Remote SSH配置即可

![vsc container切换](/images/vsc_remote_container.png)