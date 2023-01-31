---
title: "Terraform导入云资源"
date: 2022-09-18
draft: false
---


### Terraform安装

Mac 下通过Brew安装Terraform非常简单

```shell
brew install terraform
terraform --version
```


### 准备tf配置文件

```terraform
## 云CVM实例
resource "tencentcloud_instance" "myinstance" {
    
}

## Ckafka实例
resource "tencentcloud_ckafka_instance" "foo" {
}

provider "tencentcloud" {
    ### Qcloud访问的Id和Key
    secret_id  = "xxxx"
    secret_key = "xxxx"
    region = var.region
    ## 可选
    domain = "internal.tencentcloudapi.com"
}

variable "region" {
  type = string
  default = "ap-guangzhou"
}

terraform {
  required_providers {
    tencentcloud = {
      source  = "registry.terraform.io/tencentcloudstack/tencentcloud"
      version = ">=1.61.5"
      
    }
  }
}   

```

### 获取云资源信息

首先进行初始化
```shell
terraform init
```

然后获取具体实例信息
```shell
terraform import tencentcloud_ckafka_instance.foo ckafka-7k5nb444
```
相关云资源信息存放在state文件中，默认在当前目录下 terraform.tfstate

没有发现有特别好的批量把存量云资源导入terraform的方法，[Terraform在线学习文档](https://lonegunmanb.github.io/introduction-terraform/)