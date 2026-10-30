#!/bin/bash
echo -e "\033[1;33m[*] Rebuilding SlowDNS (DNSTT) via Golang...\033[0m"
apt-get install -y golang git openvpn easy-rsa >/dev/null 2>&1
rm -rf /opt/dnstt /usr/local/bin/dnstt-server
git clone https://github.com/Yukkiteru/dnstt.git /opt/dnstt >/dev/null 2>&1
cd /opt/dnstt/dnstt-server && go build -o /usr/local/bin/dnstt-server
mkdir -p /etc/slowdns
/usr/local/bin/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
    cat /etc/slowdns/server.pub > /etc/smartking4luv/slowdns_pub
systemctl restart client-dnstt || true

echo -e "\033[1;33m[*] Initializing OpenVPN Backend...\033[0m"
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
echo "yes" | ./easyrsa build-ca nopass
./easyrsa gen-req server nopass
echo "yes" | ./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey tls-auth /etc/openvpn/ta.key
cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem /etc/openvpn/ta.key /etc/openvpn/
echo -e "\033[1;32m[+] OpenVPN and SlowDNS Engines Restored.\033[0m"
