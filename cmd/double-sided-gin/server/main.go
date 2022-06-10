package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// 支持启动时显示构建日期和构建版本
// 需要通过命令 ` go build -ldflags "-X main.build=`git rev-parse HEAD`" ` 打包
var build = "not set"

func main() {
	fmt.Printf("Build: %s\n", build)
	pool := x509.NewCertPool()
	caCertPath := "./bin/tmp/ca.crt"

	caCrt, err := ioutil.ReadFile(caCertPath)
	if err != nil {
		log.Fatal("ReadFile err:", err)
		return
	}
	pool.AppendCertsFromPEM(caCrt)

	r := gin.New() //gin.Default()
	r.GET("/", func(c *gin.Context) {
		c.String(http.StatusOK, "golang gin https server!!!")
	})

	s := &http.Server{
		Addr:    ":8080",
		Handler: r,
		TLSConfig: &tls.Config{
			ClientCAs:  pool,
			ClientAuth: tls.RequireAndVerifyClientCert,
		},
	}

	if err = s.ListenAndServeTLS("./bin/tmp/cert.crt", "./bin/tmp/cert.key"); err != nil {
		log.Fatal("ListenAndServeTLS err:", err)
	}
}
