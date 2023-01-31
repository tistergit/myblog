---
title: Nginx + Ceph作为CDN源站存储方案
date: 2022-09-18
draft: false
---

## Nginx + Ceph作为CDN源站存储方案

### 旧架构
![旧架构](./img/doc_image_0_w562_h80.gif)

源站存储采用3~4台TS类机器，单机硬盘有限，扩容不方便，虽然采用链式回源的方式，新资源可以向二级、三级这样逐级添加，但会造成回源链路过长，且旧数据会经过所有存储层，带宽消耗大。2、当回源带宽突然增长时，基本无法扩容。3、同一资源重复存储了3~4份，机器利用率低。

### 新架构
![新架构](./img/doc_image_1_w641_h126.gif)

采用Ceph集群统一存储文件，当存储容量不足时，可非常方便增加存储的机器。2、Ceph每个文件只存储2份（后续可以考虑1.33份），存储机器利用率高。3、引入了Cache节点，针对热点回源可以命中Cache，减少突发大量回源对Ceph集群的请求量。4、Ceph接入采用Master、Slave两台同时活跃的方式，既可防止单点问题，又可分担流量。

### Nginx Cache配置说明

- 通用配置项目
```
user mqq mqq;
worker_processes 11;
worker_cpu_affinity auto;
pid        logs/nginx.pid;
events {
         worker_connections 10240;
}
```
worker_processes  这个参数，为什么用11，不用auto ，绑定24个CPU。考虑这个是Cache机器，只有11块ssd硬盘，这个值设置太高，硬盘IO太高，作用不大。

- Cache Path配置
```
sendfile on;
keepalive_timeout 65;
proxy_cache_path /data1/nginx_cache levels=1:2 keys_zone=my-cache1:10m max_size=230G inactive=1d;
proxy_cache_path /data2/nginx_cache levels=1:2 keys_zone=my-cache2:10m max_size=230G inactive=1d;
proxy_cache_path /data3/nginx_cache levels=1:2 keys_zone=my-cache3:10m max_size=230G inactive=1d;
proxy_cache_path /data4/nginx_cache levels=1:2 keys_zone=my-cache4:10m max_size=230G inactive=1d;
proxy_cache_path /data5/nginx_cache levels=1:2 keys_zone=my-cache5:10m max_size=230G inactive=1d;
proxy_cache_path /data6/nginx_cache levels=1:2 keys_zone=my-cache6:10m max_size=230G inactive=1d;
proxy_cache_path /data7/nginx_cache levels=1:2 keys_zone=my-cache7:10m max_size=230G inactive=1d;
proxy_cache_path /data8/nginx_cache levels=1:2 keys_zone=my-cache8:10m max_size=230G inactive=1d;
proxy_cache_path /data9/nginx_cache levels=1:2 keys_zone=my-cache9:10m max_size=230G inactive=1d;
proxy_cache_path /data10/nginx_cache levels=1:2 keys_zone=my-cache10:10m max_size=230G inactive=1d;
#proxy_cache_path /data11/nginx_cache levels=1:2 keys_zone=my-cache11:10m max_size=230G inactive=1d use_temp_path=off;
```
- sendfile on, 避免了内核层与用户层的上线文切换。作为Cache用，有大量的文件读、写操作，当然打开。
  - proxy_cache_path 说明：
/data1/nginx_cache Cache： 使用的硬盘，我们使用的是TS8-10G的机型，有11块SSD硬盘，这里不建议在OS层作软Raid,有性能损耗，且坏一块硬盘，所有的Cache数据全部失效；建议的方式是在Nginx的Cache这里配置多块硬盘。
  - levels=1:2  ： Nginx Cache缓存文件的存储方式，内部规则如下图所示：  
echo -n "/myapp/6337/bydr3dx/10011880_com.tencent.tmgp.bydr3dx_h101_1.0.7.apk" | md5sum
 根据算出来的Md5值作文件名保存，保存路径是最后一个字母(c)下后两个字母(6d) ,放在这个文件下。
  - keys_zone=my-cache1:10m ： my-cache1 这个是Cache空间的名，供下面引用，就是你的缓存空间名。10m  是10 MB的意思，这个10M是共享内存空间，1MB约可放8000个keys，根据需要缓存的文件平均大小和硬盘空间考虑来设置这个值
  - max_size=230G ：总共给Nginx Cache使用的硬盘空间大小，注意，这个空间只包含Nginx Cache的缓存文件，不包含下面user_temp_path=off时建立的 temp 文件。（下面有一个案例会讲到这块）。
  - inactive=1d ： Cache缓存文件的过期时间，1d 表示一天，同一个缓存文件，一天不使用，就算是空间没满，也会在Cache中淘汰掉。
  - use_temp_path=off  ： Nginx在向Upstream服务器请求文件时，会把请求到的文件临时存放，这个 proxy_temp_path 参数是用了设置这个的。Use_temp_path设置为Off，并不表示不使用temp目录，只是不单独存放到 proxy_temp_path 设置的目录中，Nginx会放到 proxy_cache_path 参数后台的Cache的第一层目录下，建立一个名为 temp 的目录来存放temp 文件。

### Cache比率及Upstream配置
```
split_clients $uri $my_cache {
              10% "my-cache1";
              10% "my-cache2";
              10% "my-cache3";
              10% "my-cache4";
              10% "my-cache5";
              10% "my-cache6";
              10% "my-cache7";
              10% "my-cache8";
              10% "my-cache9";
              10% "my-cache10";
              }
       proxy_temp_path /data11/proxy_temp 1 2;
       upstream dlied_back_rs {
              server xx.xx.xx.xx:8080 weight=3 max_fails=2 fail_timeout=30s;
              server xx.xx.xx.xx:8080 weight=1 max_fails=2 fail_timeout=30s ;
       }
```
- split_clients ：配置每个Cache空间的缓存比率。注意：比率加起来要是100%，不然就会有部分资源无法缓存的情况。
- proxy_temp_path ：配置nginx 从Upstream 拉取数据的缓存目录。
- upstream ： 配置Ceph接入Master和Slave的地址及权重。

### Server的配置
```
server {
	  listen 8080;
	  server_name dlied5.myapp.com dlied4.myapp.com ups-dlied5.myapp.com;
	  location / {
	        expires 30d;
	        access_log logs/upstream.log cdn_src;
	        proxy_pass http://dlied_back_rs;
	        proxy_cache $my_cache;
	        proxy_cache_key $uri;
	        proxy_cache_valid 200 302 30d;
	        proxy_cache_valid 404 60m;
	        proxy_cache_use_stale error timeout invalid_header updating;
	        proxy_redirect off;
	        proxy_cache_lock on;
	        proxy_cache_revalidate on;
		proxy_cache_min_uses 3;
		add_header X-Cache-Status $upstream_cache_status;
	        proxy_cache_purge  PURGE from xx.xx.xx.xx;
    }

}
```
- expires 30d ： 配置资源的过期时间，这个与之前的 inactive 是指一个资源在Nginx Cache里面的过期时间，这个expires 指的是资源在浏览器侧看到的过期时间。（在Http Response Header里面看到的），30d 表示30天。
- Proxy_pass : 指定存储使用的Upstream服务器名称，名称在上面用upstream定义的。
- Proxy_cache : 指定用那个Cache空间，可以指定proxy_cache_path里面定义的具体Cache名，也可以指定split_clients定义的联合Cache，如$my_cache(注意，联合Cache最好用_，不要用-，这里貌似Nginx不支持-)。
- proxy_cache_key : 这里是定义cache key的，cache_key 在Nginx内部约定中唯一的资源，Nginx里面有很多变更可以用，如:$request_uri , $uri , 这两者的区分是$request_uri带域名，$uri 不带域名。这里也会影响到Nginx cache存储的路径计算，就是上面levels里面的部分。
- proxy_cache_valid : 强制设定缓存数据的过期时间。（这个还没搞太懂，待后续补充）。
- proxy_cache_use_stale : 定义是否当后端Upstream服务器故障时，Nginx Cache返回过期的数据给Client。
- proxy_cache_lock : 当该值为 on 时，当多个客户端请求一个缓存中不存在的文件（或称之为一个MISS），只有这些请求中的第一个被允许发送至服务器。其他请求在第一个请求得到满意结果之后在缓存中得到文件。如果不启用proxy_cache_lock，则所有在缓存中找不到文件的请求都会直接与服务器通信。
- proxy_cache_revalidate : 指示NGINX在刷新来自服务器的内容时使用GET请求。如果客户端的请求项已经被缓存过了，但是在缓存控制头部中定义为过期，那么NGINX就会在GET请求中包含If-Modified-Since字段，发送至服务器端。这项配置可以节约带宽，因为对于NGINX已经缓存过的文件，服务器只会在该文件请求头中Last-Modified记录的时间内被修改时才将全部文件一起发送。
- proxy_cache_min_users : 设置了在NGINX缓存前，客户端请求一个条目的最短时间。当缓存不断被填满时，这项设置便十分有用，因为这确保了只有那些被经常访问的内容才会被添加到缓存中。该项默认值为1。
- add_header X-Cache-Status $upstream_cache_status ： 在返回的Response中加入一个X-Cache-Stauts头，该头可能的值及意义如下：
MISS——响应在缓存中找不到，所以需要在服务器中取得。这个响应之后可能会被缓存起来。
BYPASS——响应来自原始服务器而不是缓存，因为请求匹配了一个proxy_cache_bypass（见下面我可以在缓存中打个洞吗？）。这个响应之后可能会被缓存起来。
EXPIRED——缓存中的某一项过期了，来自原始服务器的响应包含最新的内容。
STALE——内容陈旧是因为原始服务器不能正确响应。需要配置proxy_cache_use_stale。
UPDATING——内容过期了，因为相对于之前的请求，响应的入口（entry）已经更新，并且proxy_cache_use_stale的updating已被设置。
REVALIDATED——proxy_cache_revalidate命令被启用，NGINX检测得知当前的缓存内容依然有效（If-Modified-Since或者If-None-Match）。
HIT——响应包含来自缓存的最新有效的内容。