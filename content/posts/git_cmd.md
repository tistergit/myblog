---
title: Git使用备忘
date: 2023-02-02
draft: false
---

### git pull提示用户名、密码问题

```shell
git config --global user.name "tisteryu"
git config --global user.email "tisteryu@xxx.com"

# 注意下面这行也需要设置，https协议不支持密钥认证
git config --global url.git@git.domain.com:.insteadOf https://git.domain.com/

```

### git 配置文件
初始化Git 的项目目录（ /project/.git/config ）或用户根目录（ ~/.gitconfig ）