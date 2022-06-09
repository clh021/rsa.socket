package gen

import (
	"crypto/x509"
	"strings"
	"testing"
)

func Test_GenerateCert(t *testing.T) {
	Init()
	_, _, err := generateCertificate(
		certificateConfig{
			isCA:        true,
			hosts:       []string{""},
			keyUsage:    x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
			extKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		},
	)
	if err != nil {
		t.Error(err)
	}
}

func Test_WriteCert(t *testing.T) {
	Init()
	caCert, caKey, err := generateCertificate(certificateConfig{
		isCA:        true,
		hosts:       []string{""},
		keyUsage:    x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		extKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
	})
	if err != nil {
		t.Error(err)
	}
	err = writeCert("ca", caCert, caKey)
	if err != nil {
		t.Error(err)
	}
}

func Test_WriteAllCerts(t *testing.T) {
	Init()
	caCert, caKey, err := generateCertificate(certificateConfig{
		isCA:        true,
		hosts:       []string{""},
		keyUsage:    x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		extKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
	})
	if err != nil {
		t.Error(err)
	}
	caParsedCertificates, err := x509.ParseCertificates(caCert)
	if err != nil {
		t.Error(err)
	}

	hosts := make([]string, 0)
	for _, h := range strings.Split(host, ",") {
		if h == "" {
			continue
		}
		hosts = append(hosts, h)
	}
	hosts = append(hosts, apiServerSubjectAlternateNames...)

	apiserverCert, apiserverKey, err := generateCertificate(certificateConfig{
		caCert:      caParsedCertificates[0],
		caKey:       caKey,
		hosts:       hosts,
		keyUsage:    x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		extKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
	})
	if err != nil {
		t.Error(err)
	}

	err = writeCert("apiserver", apiserverCert, apiserverKey)
	if err != nil {
		t.Error(err)
	}

	serviceAccountCert, serviceAccountKey, err := generateCertificate(certificateConfig{
		caCert:   caParsedCertificates[0],
		caKey:    caKey,
		hosts:    []string{""},
		keyUsage: x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature | x509.KeyUsageCertSign,
	})
	if err != nil {
		t.Error(err)
	}

	err = writeCert("service-account", serviceAccountCert, serviceAccountKey)
	if err != nil {
		t.Error(err)
	}
}
