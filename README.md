# 客户端手动导入根证书并添加到“信任的根服务站点”
# mac os x
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/new-root-certificate.crt
sudo security delete-certificate -c "<name of existing certificate>"
# windows
certutil -addstore -f "ROOT" new-root-certificate.crt
certutil -delstore "ROOT" serial-number-hex
# linux(debian,ubuntu)
sudo mkdir -p /usr/local/share/ca-certificates/my-custom-ca/
sudo cp root.crt /usr/local/share/ca-certificates/my-custom-ca/root.crt
sudo update-ca-certificates
sudo rm /usr/local/share/ca-certificates/my-custom-ca/root.crt
sudo update-ca-certificates --fresh
```