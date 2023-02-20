---
title: Docker镜像构建和Push
date: 2023-02-13
draft: false
---

## Docker镜像查看

```bash

$ docker images
REPOSITORY                                                              TAG              IMAGE ID       CREATED        SIZE
tister/mydemo                                                           v1.0             580f6ec2235c   5 hours ago    19.4MB
tisteryu-docker.pkg.coding.net/tister.coding.me/mydemo/myimage          v1.0             580f6ec2235c   5 hours ago    19.4MB
docker-gs-ping                                                          latest           053e038cb097   5 hours ago    19.4MB
tisteryu-docker.pkg.coding.net/tister.coding.me/mydemo/docker-gs-ping   latest           053e038cb097   5 hours ago    19.4MB

```
上述4个镜像，1和2的ImageID相同，3和4的ImageID相同，但是并不表示1可以推给2的仓库，tister/mydemo 和 docker-gs-ping 的仓库地址是：hub.docker.com 

## hub登录和登出

```bash
## 个人仓库 Login
$ docker login https://tisteryu-docker.pkg.coding.net/
Username: tister@qq.com
Password:
Login Succeeded

$ docker logout https://tisteryu-docker.pkg.coding.net/
Removing login credentials for tisteryu-docker.pkg.coding.net

## hub.docker.com Login
$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: tister
Password:
Login Succeeded

Logging in with your password grants your terminal complete access to your account.
For better security, log in with a limited-privilege personal access token. Learn more at https://docs.docker.com/go/access-tokens/

```

## 变更镜像的tag或Repository

```bash
$ docker image tag docker-gs-ping:latest tister/docker-gs-ping:latest
$ docker images
REPOSITORY                                                              TAG              IMAGE ID       CREATED        SIZE
tister/mydemo                                                           v1.0             580f6ec2235c   5 hours ago    19.4MB
tisteryu-docker.pkg.coding.net/tister.coding.me/mydemo/myimage          v1.0             580f6ec2235c   5 hours ago    19.4MB
docker-gs-ping                                                          latest           053e038cb097   5 hours ago    19.4MB
tister/docker-gs-ping                                                   latest           053e038cb097   5 hours ago    19.4MB
tisteryu-docker.pkg.coding.net/tister.coding.me/mydemo/docker-gs-ping   latest           053e038cb097   5 hours ago    19.4MB
tisteryu-docker.pkg.coding.net/tister.coding.me/mydemo                  docker-gs-ping   053e038cb097   5 hours ago    19.4MB

```

## 镜像推送Push

```bash
$ docker push tister/docker-gs-ping:latest
The push refers to repository [docker.io/tister/docker-gs-ping]
71a6447cbfe5: Pushed
0a24540c1e5a: Pushed
latest: digest: sha256:8098514deb6e50d1eae7cfffd600eaf322483315d3650f0922b433777efcec38 size: 739

$ docker push tisteryu-docker.pkg.coding.net/tister.coding.me/mydemo/docker-gs-ping:latest
The push refers to repository [tisteryu-docker.pkg.coding.net/tister.coding.me/mydemo/docker-gs-ping]
71a6447cbfe5: Layer already exists
0a24540c1e5a: Layer already exists
latest: digest: sha256:8098514deb6e50d1eae7cfffd600eaf322483315d3650f0922b433777efcec38 size: 739

```