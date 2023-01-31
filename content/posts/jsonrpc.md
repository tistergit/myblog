---
title: jsonrpc调用示例
date: 2022-09-18
draft: false
---

### 说明

很多平台使用jsonrpc作为接口的协议，但大家都不是太标准，这里记录一下通过不同语言jsonrpc的实现方式

### Python版本
```Python
import json
import requests


def rpc_call(url, args):
	r=requests.post(url,json=args,headers={'Content-Type': 'application/json'})
	print(r.text)

if __name__ == "__main__":
    print("start")
    url = "http://site.url"
    args = {'currentDate': "2022-09-13", 'username': "xxx",'password':"xxxx"}
    rpc_call(url,args)
    print("end")
```

### golang 
```go
package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
)

func main() {
	posturl := "http://site.url"
	fmt.Println("HTTP JSON POST URL:", posturl)

	var jsonData = []byte(`{
		"currentDate": "2022-09-13",
		"username": "xxxx",
		"password":"xxxx"}
	}`)
	// request, error := http.NewRequest("POST", posturl, bytes.NewBuffer(jsonData))
	response, err := http.Post(posturl, "application/json; charset=UTF-8", bytes.NewBuffer(jsonData))
	// request.Header.Set("Content-Type", "application/json; charset=UTF-8")

	if err != nil {
		panic(err)
	}
	defer response.Body.Close()

	fmt.Println("response Status:", response.Status)
	fmt.Println("response Headers:", response.Header)
	body, _ := ioutil.ReadAll(response.Body)
	fmt.Println("response Body:", string(body))

}

```