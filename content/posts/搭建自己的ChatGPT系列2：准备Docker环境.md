---
title: "搭建自己的ChatGPT系列2：准备Docker环境"
date: 2023-04-12
draft: true
---

## 准备Finetune使用的Docker环境

```Dockerfile

FROM nvcr.io/nvidia/pytorch:22.12-py3
LABEL org.opencontainers.image.authors="tister@qq.com"

WORKDIR /app

RUN git clone https://github.com/tloen/alpaca-lora.git

WORKDIR /app/alpaca-lora

RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip install datasets loralib sentencepiece git+https://github.com/huggingface/transformers.git bitsandbytes git+https://github.com/huggingface/peft.git gradio fire

# Patch for 1-click fine-tune
COPY lora/patches/ .
COPY scripts/ .

```

几点重要重点注意：
- pip 默认的transformers和peft包，不包含llama相关的处理，所以需要从git安装安装，不能直接从pip仓库安装
- 国内访问github很慢，有时还被墙，如果pip git+https这种方式经常失败，可以采用提前clone下这两个包，Dockerfile改用以下方式安装：

```
COPY transformers/ /transformers/
COPY peft/ /peft/ 
RUN ls -al /transformers/* /peft/*

WORKDIR /transformers
RUN pip install .
WORKDIR /peft
RUN pip install .

```

