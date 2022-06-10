package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
)

// 支持启动时显示构建日期和构建版本
// 需要通过命令 ` go build -ldflags "-X main.build=`git rev-parse HEAD`" ` 打包
var build = "not set"

type httpsHandler struct {
}

func (*httpsHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "golang https server!!!")
}

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

	s := &http.Server{
		Addr:    ":8080",
		Handler: &httpsHandler{},
		TLSConfig: &tls.Config{
			ClientCAs:  pool,
			ClientAuth: tls.RequireAndVerifyClientCert,
		},
	}

	if err = s.ListenAndServeTLS("./bin/tmp/cert.crt", "./bin/tmp/cert.key"); err != nil {
		log.Fatal("ListenAndServeTLS err:", err)
	}
}
