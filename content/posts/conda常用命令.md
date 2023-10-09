---
title: Conda常用命令
tags: ["conda"]
date: 2023-06-25
draft: false
---

#### 查看conda版本，验证是否安装
```
$ conda --version 
```
#### 更新至最新版本，也会更新其它相关包

```
$ conda update conda
```

#### 更新所有包

```bash
$ conda update --all
```

#### 更新指定的包
```
$ conda update package_name
```

#### 创建环境

创建名为env_name的新环境，并在该环境下安装名为package_name 的包，可以指定新环境的版本号，例如：conda create -n python2 python=python2.7 numpy pandas，创建了python2环境，python版本为2.7，同时还安装了numpy pandas包
```
$ conda create -n llm python=python3.10 numpy pandas
```

#### 切换至env_name环境
```
$ source activate env_name 
```

#### 退出环境

```
$ source deactivate
```

#### 显示所有已经创建的环境

```
$ conda info -e 
```


2. conda create --name new_env_name --clone old_env_name #复制old_env_name为new_env_name

3.  conda remove --name env_name –all #删除环境

4.  conda list #查看所有已经安装的包

5.  conda install package_name #在当前环境中安装包

6.  conda install --name env_name package_name #在指定环境中安装包

7.  conda remove -- name env_name package #删除指定环境中的包

8.  conda remove package #删除当前环境中的包

9.  conda create -n tensorflow_env tensorflow

conda activate tensorflow_env #conda 安装tensorflow的CPU版本

17. conda create -n tensorflow_gpuenv tensorflow-gpu

conda activate tensorflow_gpuenv #conda安装tensorflow的GPU版本

18. conda env remove -n env_name #采用第10条的方法删除环境失败时，可采用这种方法