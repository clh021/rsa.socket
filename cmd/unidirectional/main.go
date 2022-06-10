package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
)

// 支持启动时显示构建日期和构建版本
// 需要通过命令 ` go build -ldflags "-X main.build=`git rev-parse HEAD`" ` 打包
var build = "not set"

func handler(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "golang https server")
}

func main() {
	fmt.Printf("Build: %s\n", build)
	http.HandleFunc("/", handler)
	if err := http.ListenAndServeTLS(":8080", "./genBysh/.tests/tmp/cert.crt", "./genBysh/.tests/tmp/cert.key", nil); err != nil {
		log.Fatal("ListenAndServe:", err)
	}
}
