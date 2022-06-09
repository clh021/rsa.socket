package main

import (
	"crypto/tls"
	"crypto/x509"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
)

// 支持启动时显示构建日期和构建版本
// 需要通过命令 ` go build -ldflags "-X main.build=`git rev-parse HEAD`" ` 打包
var build = "not set"

func main() {
	fmt.Printf("Build: %s\n", build)
	port := flag.String("port", "8360", "port to connect")
	certFile := flag.String("certfile", "cert.pem", "trusted CA certificate")
	flag.Parse()
	cert, err := os.ReadFile(*certFile)
	if err != nil {
		log.Fatal(err)
	}
	certPool := x509.NewCertPool()
	if ok := certPool.AppendCertsFromPEM(cert); !ok {
		log.Fatalf("unable to parse cert from %s", *certFile)
	}
	config := &tls.Config{RootCAs: certPool}
	conn, err := tls.Dial("tcp", "localhost:"+*port, config)
	if err != nil {
		log.Fatal(err)
	}
	_, err = io.WriteString(conn, "Hello simple secure Server\n")
	if err != nil {
		log.Fatal("client write error:", err)
	}
	if err = conn.CloseWrite(); err != nil {
		log.Fatal(err)
	}
	buf := make([]byte, 256)
	n, err := conn.Read(buf)
	if err != nil && err != io.EOF {
		log.Fatal(err)
	}
	fmt.Println("client read:", string(buf[:n]))
	conn.Close()

	certChain := conn.ConnectionState().PeerCertificates
	for i, cert := range certChain {
		fmt.Println(i)
		fmt.Println("Issuer:", cert.Issuer)
		fmt.Println("Subject:", cert.Subject)
		fmt.Println("Version:", cert.Version)
		fmt.Println("NotAfter:", cert.NotAfter)
		fmt.Println("DNS names:", cert.DNSNames)
		fmt.Println("")
	}
}
