---
title: k8s下configMap使用
date: 2023-02-16
draft: false
---

### git pull提示用户名、密码问题

```
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: test
spec:
  containers:
    - name: test-container
      image: test:v0.1
      volumeMounts:
      - name: test-volume
        mountpath: /app/config
  volumes:
    - name: test-volume
    configMap:
      name:test-conf
      items:
      - key: test-conf
        path: config.yaml
```

### git 配置文件
初始化Git 的项目目录（ /project/.git/config ）或用户根目录（ ~/.gitconfig ）