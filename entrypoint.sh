#!/bin/bash
DHPARAM_FILE="/etc/openvpn/dhparam.pem"
DHPARAM_SIZE="1024"
OPENVPN_CONF="/etc/openvpn/server.conf"

# Create DHPARAM file
if [[ ! -f "${DHPARAM_FILE}" ]]; then
	openssl dhparam -out "${DHPARAM_FILE}" "${DHPARAM_SIZE}"
fi

if [[ -f "${OPENVPN_CONF}" ]]; then
	/usr/local/sbin/openvpn --config "${OPENVPN_CONF}"
else
	/bin/bash
fi