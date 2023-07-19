#!/bin/bash

# cf. https://qiita.com/nis_nagaid_1984/items/b8f87d41ea108d47af61
#     https://qiita.com/3244/items/8c7e6892efdb4e500be9

set -eu

help() {
  echo "Usage: $0 init"
  echo "       $0 dns HOSTNAME"
  echo "       $0 ip IPADDR"
  exit 1
}

setup_paths() {
  base_dir="$PWD"
  conf_dir="$base_dir/conf"
  subj_conf="$conf_dir/subj.conf"
  eval openssl_dir="$(openssl version -d | awk '$1 == "OPENSSLDIR:" { print $2 }')"
}

init() {
  mkdir -pv "$conf_dir"
  if [ ! -f "$subj_conf" ]; then
    cat <<EOF > "$subj_conf"
C='***'  # country name
ST='***' # state or province name
L='***'  # locality name
O='***'  # organization name
OU='***' # organization unit name
CN='***' # common name
EOF
    echo "[WARN] ### YOU NEED TO UPDATE $subj_conf ###"
  fi
  exit 0
}

if [ $# = 0 ]; then
  help
fi

setup_paths
if [ "$1" = "init" ]; then
  init
elif [ ! -f "$subj_conf" ]; then
  echo "[INFO] Run \"$0 init\" and edit $subj_conf"
  echo
  help
elif grep -E "^[A-Z]+='\\*\\*\\*'" "$subj_conf"; then
  echo "[ERROR] You have to update $subj_conf"
  exit 1
fi

. "$subj_conf"

type="$1"; shift
host="$1"; shift

ca_subj="/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN CA ($host)"
sv_subj="/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$host"

dir="servers/$host"
conf_file="openssl.cnf"
ca_key="ca.key"
ca_crt="ca.crt"
sv_key="server.key"
sv_csr="server.csr"
sv_crt="server.crt"

echo "[INFO] Generating: $type:$host"
mkdir -p "$dir"/{certs,crl}
cd "$dir"

cp /dev/null index.txt
echo "[INFO] Initialized: index.txt"
if [ ! -f serial ]; then
  echo 00 > serial
  echo "[INFO] Initialized: serial"
fi
if [ ! -f crlnumber ]; then
  echo 00 > crlnumber
  echo "[INFO] Initialized: crlnumber"
fi

# Generate conf file
case "$type" in
  dns)
    alt_name="DNS:$host"
    constraints="$alt_name"
    ;;
  ip)
    alt_name="IP:$host"
    constraints="$alt_name/255.255.255.255"
    ;;
  *)
    echo "[ERROR] Unexpected type: $type"
    echo ""
    help
    ;;
esac

awk -v "alt_name=$alt_name" -v "constraints=$constraints" \
    -f "$base_dir/modify_openssl_cnf.awk" "$openssl_dir/openssl.cnf" > "$conf_file.new"
if [ ! -f "$conf_file" ]; then
  mv "$conf_file.new" "$conf_file"
  conf_changed=true
  echo "[INFO] conf file generated: $conf_file"
elif diff -u "$conf_file" "$conf_file.new"; then
  rm -f "$conf_file.new"
  conf_changed=false
  echo "[INFO] conf file NOT changed: $conf_file"
else
  mv -v "$conf_file.new" "$conf_file"
  conf_changed=true
  echo "[INFO] conf file changed: $conf_file"
fi

# Generate CA key
if [ ! -s "$ca_key" ]; then
  openssl genrsa -out "$ca_key" 2048
  echo "[INFO] CA key generated: $ca_key"
fi

# Generate CA cert
if [ ! -f "$ca_crt" ] || $conf_changed; then
  openssl req -config "$conf_file" -days 36525 \
          -extensions v3_ca -extensions private_ca -new -x509 \
          -key "$ca_key" -subj "$ca_subj" --out "$ca_crt"
  echo "[INFO] CA cert generated: $ca_crt"
fi

# Generate server key
if [ ! -s "$sv_key" ]; then
  openssl genrsa -out "$sv_key" 2048
  echo "[INFO] server key generated: $sv_key"
fi

# Generate server CSR
if [ ! -f "$sv_csr" ] || $conf_changed; then
  openssl req -config "$conf_file" -new \
          -key "$sv_key" -subj "$sv_subj" -out "$sv_csr"
  echo "[INFO] Server CSR generated: $sv_csr"
fi

# Generate server cert
if [ ! -f "$sv_crt" ] || $conf_changed; then
  rm -f "$sv_crt"
  openssl ca -batch -config "$conf_file" -extensions usr_cert \
          -keyfile "$ca_key" -cert "$ca_crt" -in "$sv_csr" -out "$sv_crt"
  echo "[INFO] Server cert generated: $sv_crt"
fi
