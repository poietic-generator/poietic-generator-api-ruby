#!/bin/sh
# see:
# https://github.com/sameersbn/docker-apt-cacher-ng
# https://gist.github.com/dergachev/8441335

set -e
set -u

CONFPATH=/etc/apt/apt.conf.d/01proxy 
APT_PROXY_PORT="${1:-8080}"
HOST_IP=$(awk '/^[a-z]+[0-9]+\t00000000/ { printf("%d.%d.%d.%d\n", "0x" substr($3, 7, 2), "0x" substr($3, 5, 2), "0x" substr($3, 3, 2), "0x" substr($3, 1, 2)) }' < /proc/net/route)


# Decide if proxy must be enabled
PROXY_ENABLED=0
if [ -z "$APT_PROXY_PORT" ] || [ -z "$HOST_IP" ]; then
	>&2 echo "No value defined for APT_PROXY_PORT or HOST_IP. Skipping APT PROXY setup."
elif ! ruby -e "require 'socket'; Socket.tcp('$HOST_IP', $APT_PROXY_PORT, connect_timeout: 5) { exit 0 } ; exit 1" ; then
	# We use ruby to detect if port is open since netcat is not yet installed
	>&2 echo "Unable to connect to proxy on $HOST_IP:$APT_PROXY_PORT. Skipping APT PROXY setup."
else 
	PROXY_ENABLED=1
fi

# Write configuration in case proxy is here
if [ $PROXY_ENABLED -eq 1 ]; then
    cat > $CONFPATH <<-EOL
        Acquire::HTTP::Proxy "http://${HOST_IP}:${APT_PROXY_PORT}";
        Acquire::HTTPS::Proxy "false";
EOL
    cat $CONFPATH
    echo "Using host's apt proxy"
fi
