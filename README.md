Self-signed certificate utility
===============================

This is a utility for creating self-signed certificates with nameConstraints and subjectAltName.

Usage
-----

* `./gen_cert.sh init` - generate configuration file template.
* `./gen_cert.sh dns HOSTNAME` - generate self-signed CA & server certificates for HOSTNAME.
* `./gen_cert.sh ip IPADDR` - generate self-signed CA & server certificates for IPADDR.

Example
-------

```
git clone https://github.com/vmi/self-signed-cert-utils.git
cd self-signed-cert-utils
./gen_cert.sh init
# edit conf/subj.conf
./gen_cert.sh dns host.example.com
# The following files are generated:
# servers/host.example.com/ca.key - CA private key
# servers/host.example.com/ca.crt - self-signed CA certificate with nameConstraints
# servers/host.example.com/server.key - server private key
# servers/host.example.com/server.crt - server certificate with subjectAltName
```

References
----------

* 今度こそopensslコマンドを理解して使いたい:
    * [(1) ルートCAをスクリプトで作成する](https://qiita.com/3244/items/780469306a3c3051c9fe)
    * [(2) 設定ファイル（openssl.cnf）を理解する](https://qiita.com/3244/items/8c7e6892efdb4e500be9)
    * [(3) CA証明書の拡張設定を検証する](https://qiita.com/3244/items/2a2a2dc6cd1e2e35beb9)
    * [(4) サーバー／クライアント証明書を一括生成する](https://qiita.com/3244/items/2618429ebe6dc16c074e)
* [Chromeに怒られないオレオレ証明書の作り方
](https://qiita.com/masahiro-aoike/items/dbf17fa03c5973ce9068)
* [SAN(Subject Alternative Name) のオレオレ証明書
](https://qiita.com/nis_nagaid_1984/items/b8f87d41ea108d47af61)
* [社内検証環境用にプライベート認証局立ててみた](https://developers.gmo.jp/14928/)

[EOF]
