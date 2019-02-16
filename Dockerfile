FROM centos:7
MAINTAINER Juan Manuel Carrillo Moreno "inetshell@gmail.com"

ENV OPENVPN_VERSION="openvpn-2.4.5" \
    DHPARAM_SIZE="2048" \
    SCRIPT_SECURITY="3" \
    KEEPALIVE="10 20" \
    PROTO="tcp4-server" \
    CIPHER="AES-256-CBC" \
    NCP_CIPHERS="AES-256-GCM:AES-256-CBC" \
    AUTH="SHA512" \
    SERVER="192.168.112.0 255.255.240.0" \
    LPORT="1194" \
    MAX_CLIENTS="1024" \
    COMPRESS="lz4" \
    TOPOLOGY="subnet" \
    SCRAMBLE="reverse" \
    CUSTOM_OPTIONS=""

# Get the OpenVPN source and XOR patch
ADD http://build.openvpn.net/downloads/releases/${OPENVPN_VERSION}.tar.gz /tmp
ADD https://github.com/clayface/openvpn_xorpatch/archive/master.zip /tmp

WORKDIR /tmp

RUN \
# Update YUM cache
  yum install -y epel-release && \
  yum update -y && \
# Install dependencies and clean YUM cache
  yum install -y iptables autoconf.noarch automake file gcc libtool patch quilt git make rpm-build zlib-devel pam-devel openssl openssl-devel lzo-devel lz4-devel.x86_64 net-tools cmake.x86_64 && \
  yum install -y socat && \
  yum clean all && \
# Extract openvpn source
  unzip /tmp/master.zip && \
  tar xvzf /tmp/${OPENVPN_VERSION}.tar.gz && \
# Apply XOR patch
  mv openvpn_xorpatch-master/openvpn_xor.patch ${OPENVPN_VERSION}/ && \
  cd ${OPENVPN_VERSION}/ && \
  git apply -v openvpn_xor.patch && \
# Build OpenVPN
  autoreconf -i -v -f && \
  ./configure && \
  make && \
  make install && \
# Remove working directory
  rm -rf /tmp/* && \
# Create OpenVPN directories
  mkdir /etc/openvpn /etc/openvpn/ccd /var/run/openvpn

COPY openvpn.conf.j2 /root/openvpn.conf.j2

COPY entrypoint.sh /entrypoint.sh

# Set permissions to entrypoint.sh
RUN chmod u+x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
