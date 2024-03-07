---
title: "免费https证书申请"
date: 2024-03-04
draft: false
---

### 前言

当前各浏览器都强制要求网站使用https协议，微信小程序也是，所以这里总结一下怎么在ubuntu下申请一个免费的、支持https的Nginx服务器

### 软件安装

免费https证书最有名的软件，当然首推acme.sh了
- 安装acme.sh
```shell
curl https://get.acme.sh | sh -s email=tister@qq.com
```
- 获取证书
```shell
acme.sh --issue -d tister.cn -d www.tister.cn -d sh.tister.cn --server zerossl --webroot /data/tister.cn
```
其中，-d 参数后面是证书域名，域名可以是多个。注意：这里的域名最好与nginx.conf 中域名要一致,如果还是失败，可以换一个提供商试试，--server ,[详见](https://github.com/acmesh-official/acme.sh/wiki/Server)

- 安装证书

```shell
sudo mkdir -p /etc/nginx/ssl
sudo chown -R ubuntu /etc/nginx/ssl

acme.sh --install-cert -d tister.cn -d www.tister.cn -d sh.tister.cn --key-file       /etc/nginx/ssl/key.pem  --fullchain-file /etc/nginx/ssl/cert.pem 
```

- nginx ssl配置

```
server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  crossfit.tister.cn;
    root         /data/crossfit.tister.cn;
    

    ssl_certificate "/etc/nginx/ssl/cert.pem";
    ssl_certificate_key "/etc/nginx/ssl/key.pem";
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout  10m;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;

    error_page 404 /404.html;
        location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
        location = /50x.html {
    }
}
```







