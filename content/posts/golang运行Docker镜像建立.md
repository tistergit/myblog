---
title: grpc Docker镜像使用
date: 2023-02-07
draft: false
---

## 构建grpc运行Docker镜像

[代码地址](https://github.com/grpc/grpc-go/tree/master/examples/helloworld)

grpc 服务端和客户端，下面过程是怎么通过Docker来运行一个最简单的grpc server程序

编译代码，在mac下编译后在Linux下运行，所以需要交叉编译

```shell
$ cd greeter_server
$ CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build
$ ls -lh
-rwxr-xr-x   1 tisteryu  staff    11M  2  7 10:57 greeter_server
```

- golang:alpine
镜像文件100M+，包含golang sdk等文件，适合用它来编译go语言源文件并运行

- alpine:latest
基础linux系统，文件3M左右，不包含golang sdk，只包含最基础的几个libc libssl so库

Dockerfile 文件
```
# 表示依赖 alpine 最新版
FROM alpine:latest

ENV VERSION 1.1

# 在容器根目录 创建一个 apps 目录
WORKDIR /apps

# 挂载容器目录
# VOLUME ["/apps/conf"]

# 拷贝当前目录下 go_docker_demo1 可以执行文件
COPY greeter_server/greeter_server /apps/golang_app

# 拷贝配置文件到容器中
# COPY conf/config.toml /apps/conf/config.toml

# 设置时区为上海
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo 'Asia/Shanghai' >/etc/timezone

# 设置编码
ENV LANG C.UTF-8

# 暴露端口
EXPOSE 50051

# 运行golang程序的命令
ENTRYPOINT ["/apps/golang_app"]
```

build镜像

```shell
$ docker build -t go_docker_demo1:v1.2 .
```

Run镜像

```shell
$ docker run -d --name my-go_docker_demo1 -p 50051:50051 go_docker_demo1:v1.2

```

## 构建grpc编译和运行Docker镜像

上面生成的只是grpc的运行镜像，运行文件是在os下采用go build编译生成的，下面介绍的是通过一个Dockerfile，既可编译，也可运行grpc程序，同时还想运行镜像足够小，Dockerfile.multistage：

```
## Build
FROM golang:1.19-alpine AS build

WORKDIR /app

COPY . ./
RUN go mod download

WORKDIR /app/greeter_server

RUN go build -o /docker-gs-ping

## Deploy
FROM alpine:latest

WORKDIR /

COPY --from=build /docker-gs-ping /docker-gs-ping

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/docker-gs-ping"]

```

```shell
$ docker build -t docker-gs-ping:multistage -f Dockerfile.multistage .

```

可以看到生成的镜像大小比较：
```
$ docker image ls

REPOSITORY       TAG          IMAGE ID       CREATED              SIZE
docker-gs-ping   multistage   e3fdde09f172   About a minute ago   27.1MB
docker-gs-ping   latest       336a3f164d0f   About an hour ago    540MB
```


### Docker日常命令

```shell
# 强制重新生成镜像，但也会用依赖镜像Cache
$ sudo docker compose up -d --build --force-recreate

# 清空镜像缓存
$ docker system prune -a

# 运行镜像
$ sudo docker run -t -d ubuntu:22.04

# 进入Container，2f 是CONTAINER ID
sudo docker exec -it 2f /bin/sh   

# 禁用多阶段并行编译。多阶段编译有时有上下文依赖，偶现 runc run failed: unable to start container process: exec: "/bin/sh": stat /bin/sh: no such file or directory 问题，可通过临时关闭并行编译解决
$ DOCKER_BUILDKIT=0 sudo docker compose up -d --build

```