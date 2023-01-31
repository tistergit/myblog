---
title: Go语音中优雅处理Json和Gorm
date : 2022-12-06
draft: false
---

在使用Go开发web项目的过程中, 数据库读写操作与JSON格式的输入输出是两块最基础的模块, Go的标准库已经帮我们做了很多, 熟悉gorm.io/gorm与encoding/json这两个库能帮我们更自在地开发web应用.

现实情况是，遇到一个时间比较处理的问题，有多个时间字段，有部分格式是：

```json
{
		"instanceId":"ckafka-8gra88zg",
		"deadlineTime":"2020-11-30T14:20:28.000Z",
		"createTime":"2021-08-02 19:59:23",
		"updateTime":"2021-08-02 19:59:23",
		"syncTime":"",
		"deleted":0 ,
		"instanceCreateTime":""
	}
```
要把上述Json数据解析后存储到DB中。上面的数据中的日期有三类：
- 标准的yyyy-MM-dd HH:mm:ss 格式
- syncTime空字符串格式
- deadlineTime: RFC 3339 格式

一些预备知识，go语言中，把json字符串转成struct通常使用 json.Unmarshal 这个方法,它的典型用法是：
func Unmarshal(data []byte, v interface{})
data : 传入的json字符byte
v : 目标struct 

我的做法是，把json和gorm的结构体统一在一直结构体中，既实现Json的解码，也实现与DB的映射。
```go
type TN1 struct {
	InstanceId         string   `json:"instanceId" gorm:"column:instanceId;primaryKey;NOT NULL"`
	InstanceCreateTime NullTime `json:"instanceCreateTime" gorm:"column:instanceCreateTime"`
	DeadlineTime       NullTime `json:"deadlineTime" gorm:"column:deadlineTime" `
	CreateTime         NullTime `json:"createTime" gorm:"column:createTime"`
	UpdateTime         NullTime `json:"updateTime" gorm:"column:updateTime"`
	SyncTime           NullTime `json:"syncTime" gorm:"column:syncTime"`
	Deleted            int      `json:"deleted" gorm:"column:deleted"`
}
```

json.Unmarshal 支持的结构体字段类型一般只支持基础类型，自定义类型需要实现 UnmarshalJSON 方法。
如下：
```go
type NullTime struct {
	sql.NullTime 
}

func (v *NullTime) UnmarshalJSON(data []byte) error {
	value := strings.Trim(string(data), `"`) //get rid of "
	if value == "" || value == "null" {
		return nil
	}
	t, err := dateparse.ParseAny(value)
	if err != nil {
		v.Valid = false
		return err
	}
	v.Valid = true
	v.Time = t
	return nil
}
```

这里用到了一个非常神奇的库：github.com/araddon/dateparse ， 它能parse多种日期格式，强烈推荐使用。


```go
package logic

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/araddon/dateparse"
	"github.com/gofrs/uuid"
	"github.com/jinzhu/copier"
)

const TEST_JSON_STRING string = `
	{
		"instanceId":"ckafka-8gra88zg",
		"deadlineTime":"2020-11-30T14:20:28.000Z",
		"createTime":"2021-08-02 19:59:23",
		"updateTime":"2021-08-02 19:59:23",
		"syncTime":"",
		"deleted":0 ,
		"instanceCreateTime":""
	}
	`

type TN1 struct {
	InstanceId         string   `json:"instanceId" gorm:"column:instanceId;primaryKey;NOT NULL"`
	InstanceCreateTime NullTime `json:"instanceCreateTime" gorm:"column:instanceCreateTime"`
	DeadlineTime       NullTime `json:"deadlineTime" gorm:"column:deadlineTime" `
	CreateTime         NullTime `json:"createTime" gorm:"column:createTime"`
	UpdateTime         NullTime `json:"updateTime" gorm:"column:updateTime"`
	SyncTime           NullTime `json:"syncTime" gorm:"column:syncTime"`
	Deleted            int      `json:"deleted" gorm:"column:deleted"`
}
type NullTime struct {
	sql.NullTime
}

func (v *NullTime) UnmarshalJSON(data []byte) error {
	value := strings.Trim(string(data), `"`) //get rid of "
	if value == "" || value == "null" {
		return nil
	}
	t, err := dateparse.ParseAny(value)
	if err != nil {
		v.Valid = false
		return err
	}
	v.Valid = true
	v.Time = t
	return nil
}

// TableName 表名
func (t *TN1) TableName() string {
	return "t_test_tister"
}


func TestTn1(t *testing.T) {

	jsonObj := TN1{}
	bo := TN1{}
	if err := json.Unmarshal([]byte(TEST_JSON_STRING), &jsonObj); err != nil {
		t.Error(err)
	}
	t.Log(jsonObj)
	if err := copier.Copy(&bo, &jsonObj); err != nil {
		t.Error(err)
	}
	u2, _ := uuid.NewV4()
	bo.InstanceId = "TN1 " + u2.String()
	t.Log(bo)

	if err := db.Save(&bo).Error; err != nil {
		t.Error(err)
	}

}

```

[参考1](https://medium.com/gothicism/how-to-handle-user-datatypes-in-golang-with-json-and-sql-database-a62d5304b0db)
[参考2](https://medium.com/aubergine-solutions/how-i-handled-null-possible-values-from-database-rows-in-golang-521fb0ee267)
[参考3](https://blog.csdn.net/EI__Nino/article/details/107346630)
[参考4](https://zhuanlan.zhihu.com/p/21933959)