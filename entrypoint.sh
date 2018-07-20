#!/bin/bash
OPENVPN_CONF="/etc/openvpn/server.conf"

# Create symlink to stdout
rm -rf /var/log/openvpn.log
ln -s /dev/stdout /var/log/openvpn.log

# Add firewall rules
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o ovpns1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i ovpns1 -o eth0 -j ACCEPT

# Run OpenVPN service
/usr/local/sbin/openvpn --config "${OPENVPN_CONF}"
