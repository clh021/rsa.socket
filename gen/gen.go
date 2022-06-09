package gen

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"flag"
	"fmt"
	"math/big"
	"net"
	"os"
	"time"
)

var (
	notBefore, notAfter time.Time
	serialNumberLimit   *big.Int
	rsaBits             = 2048
	host                string
)

var apiServerSubjectAlternateNames = []string{
	"127.0.0.1",
	"localhost",
	"kubernetes",
	"kubernetes.default",
	"kubernetes.default.svc",
}

type certificateConfig struct {
	isCA        bool
	caCert      *x509.Certificate
	caKey       *rsa.PrivateKey
	hosts       []string
	keyUsage    x509.KeyUsage
	extKeyUsage []x509.ExtKeyUsage
}

func Init() {
	notBefore = time.Now()
	notAfter = notBefore.Add(365 * 24 * time.Hour)
	serialNumberLimit = new(big.Int).Lsh(big.NewInt(1), 128)

	flag.StringVar(&host, "host", "", "Comma-separated hostnames and IPs to generate a certificate for")
}

func writeCert(name string, cert []byte, key *rsa.PrivateKey) error {
	certFilename := fmt.Sprintf("%s.pem", name)
	keyFilename := fmt.Sprintf("%s-key.pem", name)

	certFile, err := os.Create(certFilename)
	if err != nil {
		return err
	}
	pem.Encode(certFile, &pem.Block{Type: "CERTIFICATE", Bytes: cert})
	certFile.Close()
	fmt.Printf("wrote %s\n", certFilename)

	keyFile, err := os.OpenFile(keyFilename, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0600)
	if err != nil {
		return err
	}
	pem.Encode(keyFile, &pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: x509.MarshalPKCS1PrivateKey(key),
	})
	keyFile.Close()
	fmt.Printf("wrote %s\n", keyFilename)
	return nil
}

func generateCertificate(c certificateConfig) ([]byte, *rsa.PrivateKey, error) {
	serialNumber, err := rand.Int(rand.Reader, serialNumberLimit)
	if err != nil {
		return nil, nil, err
	}

	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return nil, nil, err
	}

	template := x509.Certificate{
		SerialNumber: (serialNumber),
		Subject: pkix.Name{
			Organization: []string{"Kubernetes"},
		},
		NotBefore: notBefore,
		NotAfter:  notAfter,

		KeyUsage:              c.keyUsage,
		ExtKeyUsage:           c.extKeyUsage,
		BasicConstraintsValid: true,
	}
	if c.hosts[0] != "" {
		template.Subject.CommonName = c.hosts[0]
	}

	if c.isCA {
		c.caCert = &template
		c.caKey = key
	}

	for _, h := range c.hosts {
		if ip := net.ParseIP(h); ip != nil {
			template.IPAddresses = append(template.IPAddresses, ip)
		} else {
			template.DNSNames = append(template.DNSNames, h)
		}
	}

	derBytes, err := x509.CreateCertificate(rand.Reader, &template, c.caCert, &key.PublicKey, c.caKey)
	if err != nil {
		return nil, nil, err
	}

	return derBytes, key, nil
}
