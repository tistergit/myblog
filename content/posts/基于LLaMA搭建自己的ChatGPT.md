---
title: "基于LLaMA搭建自己的ChatGPT"
date: 2023-04-12
draft: false
---

### 开篇

ChatGPT已经火的一塌糊涂了，完全无法置身事外，下面我们来看看怎么使用LLaMA大模型搭建一套自己的ChatGPT



### 名词

- 模型
- 大模型
### 什么是Finetune
Finetune是指在一个已经预先训练好的机器学习模型的基础上，通过在特定领域或任务的数据集上重新训练模型，以进一步提高其性能。这个过程通常涉及到在已经预训练好的模型上微调参数，以适应新的数据集和任务。

例如，在自然语言处理中，可以使用一个在大规模语料库上预先训练好的语言模型，如BERT或GPT，然后在特定的文本分类任务中，使用任务特定的数据集对模型进行Finetune。在这种情况下，模型会保留在预训练期间获得的大量通用知识，同时在新任务上通过Finetune进行微调，以更好地适应新的任务和数据集。

通过Finetune，可以利用预训练模型的大量通用知识，以及更少的特定任务数据来获得更好的性能。这使得Finetune成为一种非常有效的迁移学习方法。

您可以将Finetune理解为对通用大模型的精调。通常，预先训练的模型是使用大量数据在通用任务上进行训练，例如在大规模语料库上进行自然语言处理预训练。这样的模型在处理自然语言时已经具有一定的语义理解能力，可以处理许多不同的自然语言处理任务。

但是，对于某些具体的任务，例如文本分类或命名实体识别，预先训练的模型可能需要进一步调整，以更好地适应任务特定的数据和目标。这就需要对模型进行Finetune，通过在任务特定的数据集上微调模型参数，以进一步提高模型的性能。

因此，Finetune可以被视为在预先训练的模型的基础上进行的一种精细调整，以适应任务特定的数据和目标。这种方法旨在利用预先训练的模型所学习的通用特征，同时通过微调特定任务的相关参数，以获得更好的性能。

### 使用 Docker 和 Alpaca LoRA 对 LLaMA 65B 大模型进行 Fine-Tune

![Alt text](/images/llama/Architecture_Overview.png)

1.一块Nvidia的显卡，推理可以通过llama.cpp，只使用CPU，不需要GPU即可，但是训练必须要GPU

2.安装Cuda Driver
有两种安装方式，一种包管理器，另外一种二进制包。
[NVIDIA Linux drivers](https://www.nvidia.com/en-us/drivers/unix/)

The NVIDIA driver requires that the kernel headers and development packages for the running version of the kernel be installed at the time of the driver installation, as well whenever the driver is rebuilt. For example, if your system is running kernel version 4.4.0, the 4.4.0 kernel headers and development packages must also be installed.
The kernel headers and development packages for the currently running kernel can be installed with:
```
$ sudo apt-get install linux-headers-$(uname -r)

```
Install the CUDA repository public GPG key. This can be done via the cuda-keyring package or a manual installation of the key. The usage of apt-key is deprecated.
```
$ distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
$ wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-keyring_1.0-1_all.deb
$ sudo dpkg -i cuda-keyring_1.0-1_all.deb

```

Update the APT repository cache and install the driver using the cuda-drivers meta-package. Use the --no-install-recommends option for a lean driver install without any dependencies on X packages. This is particularly useful for headless installations on cloud instances.

```
$ sudo apt-get update
$ sudo apt-get -y install cuda-drivers
```
Follow the post-installation steps in the CUDA Installation Guide for Linux to setup environment variables, NVIDIA persistence daemon (recommended) and to verify the successful installation of the driver.

1. 安装 Docker

```
curl https://get.docker.com | sh \
  && sudo systemctl --now enable docker

```

4. 安装 NVIDIA Container Toolkit

```
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

```
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

## test 
sudo docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi

```
**注意：**上述代码在tlinux上不可用，因为tlinux改了系统原ID和版本


## 参数说明

- MICRO_BATCH_SIZE: 参数指定了每个GPU设备上运行的微小批量（mini-batch）大小。这个参数通常是fine-tuning的一个超参数，需要根据硬件和数据集大小进行调整。微小批量是指从整个训练集中取出一小部分样本进行一次前向传播和反向传播的计算。在每个微小批量内，梯度更新是在GPU上进行的，因此微小批量的大小通常是由GPU的内存容量来确定的。MICRO_BATCH_SIZE的值越大，每个微小批量包含的样本数量就越多，因此计算效率更高。但是如果超过了GPU内存的容量，就会出现OOM（out of memory）错误，导致训练无法进行。因此在选择MICRO_BATCH_SIZE时需要平衡计算效率和GPU内存容量之间的权衡。一般来说，MICRO_BATCH_SIZE的值通常在16到32之间，并且需要根据具体的硬件和数据集大小进行调整。
- BATCH_SIZE: 是指在进行模型训练时，每次从训练集中取出的样本数量。这个参数通常也是模型训练的一个超参数。与MICRO_BATCH_SIZE不同，BATCH_SIZE是指一次性从训练集中取出的样本数量，而不是将样本划分为多个微小批量。BATCH_SIZE的值通常会比MICRO_BATCH_SIZE大得多，因为它不仅受到GPU内存容量的限制，还受到CPU和GPU之间的数据传输速度的限制。BATCH_SIZE的值越大，每个训练步骤中包含的样本数量就越多，因此计算效率更高。但是如果BATCH_SIZE设置得太大，就会导致训练过程中内存的占用过高，从而可能会导致OOM错误。一般来说，BATCH_SIZE的值通常在32到128之间，并且需要根据具体的硬件和数据集大小进行调整。
- EPOCHS：表示整个训练数据集被遍历的次数。例如，如果一个数据集有10000个样本，BATCH_SIZE为32，那么一个epoch将会进行10000/32=313次迭代。通常情况下，需要通过多次epoch来不断优化模型的训练效果。
- LEARNING_RATE：表示在每次参数更新时，参数的更新量大小，也就是学习率。学习率决定了模型在每次迭代中参数更新的速度。通常情况下，需要根据具体的任务和模型结构来调整学习率的大小。
- CUTOFF_LEN：表示输入到模型中的文本最大长度。如果输入文本的长度超过了这个阈值，那么将会被截断。这个参数的设置需要根据模型的输入格式和任务需要进行调整。
- LORA_R：表示LORA模型中的reward。reward是指模型为输入生成的文本的质量，也就是模型生成的文本与期望输出的文本之间的相似度。
- LORA_ALPHA：表示LORA模型中的alpha值。alpha值是用来调整reward和KL散度之间的权重的。
- LORA_DROPOUT：表示LORA模型中的dropout值。dropout是一种防止过拟合的技术，它会在训练过程中随机将一些神经元置为0，从而降低神经网络的复杂度。
- VAL_SET_SIZE：表示用于验证的数据集的大小。训练过程中，通常会将一部分数据集留出来用于验证，以便及时监测模型的训练效果。验证集的大小需要根据具体的数据集和任务进行设置。

