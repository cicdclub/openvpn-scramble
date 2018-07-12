#!/bin/bash
DHPARAM_FILE="/etc/openvpn/dhparam.pem"
DHPARAM_SIZE="1024"
OPENVPN_CONF="/etc/openvpn/server.conf"

# Create symlink to stdout
rm -rf /var/log/openvpn.log
ln -s /dev/stdout /var/log/openvpn.log

# Create DHPARAM file
if [[ ! -f "${DHPARAM_FILE}" ]]; then
	openssl dhparam -out "${DHPARAM_FILE}" "${DHPARAM_SIZE}"
fi




# Run server
if [[ -f "${OPENVPN_CONF}" ]]; then
	/usr/local/sbin/openvpn --config "${OPENVPN_CONF}" &
	# Add firewall rules
	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
	iptables -A FORWARD -i eth0 -o ovpns1 -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i ovpns1 -o eth0 -j ACCEPT
else
	/bin/bash
fi
