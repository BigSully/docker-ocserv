#!/bin/sh

cp -r /app/ocserv/  /etc/

sed -i 's/^#\(connect-script = \).*/\1\/etc\/ocserv\/connect.sh/'  /etc/ocserv/ocserv.conf
sed -i 's/^#\(disconnect-script = \).*/\1\/etc\/ocserv\/disconnect.sh/'  /etc/ocserv/ocserv.conf


## ip rannge and dns
sed -i 's/^ipv4-network = 192.168.1.0/#\0\nipv4-network = 172.16.73.0/' /etc/ocserv/ocserv.conf
sed -i 's/^dns = 192.168.1.2/#\1\ndns = 1.1.1.1\ndns = 1.0.0.1/' /etc/ocserv/ocserv.conf
#sed -i 's/^dns = 192.168.1.2/#\1\ndns = 8.8.8.8\ndns = 8.8.4.4/' /etc/ocserv/ocserv.conf


## clear all routing rules
sed -i 's/^route/#route/' /etc/ocserv/ocserv.conf
sed -i 's/^no-route/#no-route/' /etc/ocserv/ocserv.conf


## group and user config
sed -i 's/^#\(auto-select-group\)/\1/' /etc/ocserv/ocserv.conf
sed -i 's/^#\(config-per-group\)/\1/' /etc/ocserv/ocserv.conf
sed -i 's/^#\(config-per-user\)/\1/' /etc/ocserv/ocserv.conf

set -x \
	&& sed -i 's/\.\/sample\.passwd/\/etc\/ocserv\/ocpasswd/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/\(max-same-clients = \)2/\110/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/\.\.\/tests/\/etc\/ocserv/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/#\(compression.*\)/\1/' /etc/ocserv/ocserv.conf \
	&& sed -i '/\[vhost:www.example.com\]/,$d' /etc/ocserv/ocserv.conf



if [ ! -f /etc/ocserv/certs/server-key.pem ] || [ ! -f /etc/ocserv/certs/server-cert.pem ]; then
	# Check environment variables
	if [ -z "$CA_CN" ]; then
		CA_CN="VPN CA"
	fi

	if [ -z "$CA_ORG" ]; then
		CA_ORG="Big Corp"
	fi

	if [ -z "$CA_DAYS" ]; then
		CA_DAYS=9999
	fi

	if [ -z "$SRV_CN" ]; then
		SRV_CN="www.example.com"
	fi

	if [ -z "$SRV_ORG" ]; then
		SRV_ORG="MyCompany"
	fi

	if [ -z "$SRV_DAYS" ]; then
		SRV_DAYS=9999
	fi

	# No certification found, generate one
	mkdir /etc/ocserv/certs
	cd /etc/ocserv/certs
	certtool --generate-privkey --outfile ca-key.pem
	cat > ca.tmpl <<-EOCA
	cn = "$CA_CN"
	organization = "$CA_ORG"
	serial = 1
	expiration_days = $CA_DAYS
	ca
	signing_key
	cert_signing_key
	crl_signing_key
	EOCA
	certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca.pem
	certtool --generate-privkey --outfile server-key.pem 
	cat > server.tmpl <<-EOSRV
	cn = "$SRV_CN"
	organization = "$SRV_ORG"
	expiration_days = $SRV_DAYS
	signing_key
	encryption_key
	tls_www_server
	EOSRV
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

fi
