---
title: SQL使用备忘
date: 2023-02-18
draft: false
---

### 查询A表中有多少条数据在B表中

说通俗一点就是A.ID那列的内容，有多少存在于B.ID那列
```sql
select 
  A.ID, 
  A.NAME 
from 
  表A 
where EXISTS(select * from 表B where A.ID=B.ID) 
```


### 查询A表中有多少条数据在B表中【不存在】

说通俗一点就是A.ID那列的内容，有多少【不存在】于B.ID那列

```sql
select 
  A.ID, 
  A.NAME 
from 
  表A 
where NOT EXISTS(select * from 表B where A.ID=B.ID) 
```

