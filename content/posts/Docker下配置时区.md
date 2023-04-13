---
title: "Docker下配置时区"
date: 2023-04-13
draft: false
---

### Docker下配置时区

```shell
# Fix timezone issue
ENV TZ=Asia/Shanghai
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
```