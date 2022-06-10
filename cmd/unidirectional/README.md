谷歌会提示`NET::ERR_CERT_COMMON_NAME_INVALID`
经验证，生成网站证书时应该要设置 `X509v3 Subject Alternative Name` 字段
经验证，域名设置始终与访问的端口无关
经验证，可以直接使用根域名
经验证， `X509v3 Subject Alternative Name` 字段可以实现通配符域名，但是仅针对三级域名(chrome测试)，二级域名通配符无效
经验证，不能给IP地址颁发证书，会提示`NET::ERR_CERT_COMMON_NAME_INVALID`