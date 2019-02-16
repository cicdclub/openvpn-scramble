#!/bin/bash
OPENVPN_CONF="/etc/openvpn/server.conf"
DHPARAM_PATH="/etc/openvpn/dhparam.pem"

if [[ "${CONFIG_SOURCE}" == "ENV" ]]; then
  echo "Generating openvpn.conf"
  sed -e "s|{{ SCRIPT_SECURITY }}|${SCRIPT_SECURITY}|g" \
      -e "s|{{ KEEPALIVE }}|${KEEPALIVE}|g" \
      -e "s|{{ PROTO }}|${PROTO}|g" \
      -e "s|{{ CIPHER }}|${CIPHER}|g" \
      -e "s|{{ NCP_CIPHERS }}|${NCP_CIPHERS}|g" \
      -e "s|{{ AUTH }}|${AUTH}|g" \
      -e "s|{{ SERVER }}|${SERVER}|g" \
      -e "s|{{ LPORT }}|${LPORT}|g" \
      -e "s|{{ MAX_CLIENTS }}|${MAX_CLIENTS}|g" \
      -e "s|{{ COMPRESS }}|${COMPRESS}|g" \
      -e "s|{{ TOPOLOGY }}|${TOPOLOGY}|g" \
      -e "s|{{ SCRAMBLE }}|${SCRAMBLE}|g" \
      -e "s|{{ CUSTOM_OPTIONS }}|${CUSTOM_OPTIONS}|g" \
      /root/openvpn.conf.j2 > "${OPENVPN_CONF}"

  if [[ -f "${DHPARAM_PATH}" ]]; then
    echo "DHPARAM file exists"
  else
    echo "Generating DHPARAM file"
    openssl dhparam -out "${DHPARAM_PATH}" "${DHPARAM_SIZE}"
  fi

  echo "Generating cert files"
  if [[ -z ${BASE64_CA_CRT} ]] || [[ -z ${BASE64_SERVER_CRT} ]] || [[ -z ${BASE64_SERVER_KEY} ]] || [[ -z ${BASE64_TLS_AUTH} ]]; then
    echo "ERROR: BASE64_CA_CRT, BASE64_SERVER_CRT, BASE64_SERVER_KEY and BASE64_TLS_AUTH variables must be defined"
    exit 1
  fi
  
  echo "${BASE64_CA_CRT}" | base64 -d > "/etc/openvpn/ca.crt"
  chmod 700 "/etc/openvpn/ca.crt"

  echo "${BASE64_SERVER_CRT}" | base64 -d > "/etc/openvpn/server.crt"
  chmod 700 "/etc/openvpn/server.crt"

  echo "${BASE64_SERVER_KEY}" | base64 -d > "/etc/openvpn/server.key"
  chmod 700 "/etc/openvpn/server.key"

  echo "${BASE64_TLS_AUTH}" | base64 -d > "/etc/openvpn/tls_auth"
  chmod 700 "/etc/openvpn/tls_auth"
elif [[ "${CONFIG_SOURCE}" == "FILE" ]]; then
  if [[ ! -f "${OPENVPN_CONF}" ]]; then
    echo "ERROR: OpenVPN config file does not exists. Verify file ${OPENVPN_CONF}"
    exit 1
  fi
else
  echo "ERROR: CONFIG_SOURCE must be ENV or FILE."
  exit 1
fi

echo "Adding firewall rules"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o ovpns1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i ovpns1 -o eth0 -j ACCEPT

echo "Creating tun device"
mkdir -p /dev/net
if [[ ! -c /dev/net/tun ]]; then
  mknod /dev/net/tun c 10 200
fi

echo "Run OpenVPN service"
/usr/local/sbin/openvpn --config "${OPENVPN_CONF}"
