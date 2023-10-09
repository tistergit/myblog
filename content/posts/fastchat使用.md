---
title: FastChat使用
tags: ["fschat", "llm"]
date: 2023-06-13
draft: false
---

### 通过FastChat启动多个模型

```bash
## controller
python3 -m fastchat.serve.controller --host 0.0.0.0 &

## openai serve
python3 -m fastchat.serve.openai_api_server --host 0.0.0.0 --port 8000

## workers 

# worker 0
CUDA_VISIBLE_DEVICES=0,1 python3 -m fastchat.serve.model_worker --model-path /app/models/vicuna-13b --controller http://localhost:21001 --port 31000 --worker http://localhost:31000 --num-gpus 2 --host 0.0.0.0
# worker 1
CUDA_VISIBLE_DEVICES=2,3 python3 -m fastchat.serve.model_worker --model-path /app/models/Ziya-LLaMA-13B  --controller http://localhost:21001 --port 31001 --worker http://localhost:31001 --num-gpus 2 --host 0.0.0.0 --model-name ziya-llama-13b

## gradio server (可选)
python3 -m fastchat.serve.gradio_web_server --port 8080 --model-list-mode=reload &

```