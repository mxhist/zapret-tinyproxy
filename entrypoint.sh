#!/usr/bin/env bash
set -euo pipefail

PROXY_PORT="${PROXY_PORT:-8888}"
ALLOWED_NETS="${ALLOWED_NETS:-192.168.1.0/24}"
TPWS_ARGS="${TPWS_ARGS:---split-pos=1 --disorder --tlsrec=1 --mss=1460}"

echo "[i] Starting tpws with args: $TPWS_ARGS"
/usr/local/bin/tpws \
  --proxy \
  --port=988 \
  $TPWS_ARGS \
  &

mkdir -p /var/log/tinyproxy
touch /var/log/tinyproxy/tinyproxy.log
chown nobody:nogroup /var/log/tinyproxy/tinyproxy.log

cat > /etc/tinyproxy/tinyproxy.conf <<EOF
User nobody
Group nogroup
Port ${PROXY_PORT}
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"

$(echo "$ALLOWED_NETS" | tr ',' '\n' | sed 's/^/Allow /')

LogFile "/var/log/tinyproxy/tinyproxy.log"
LogLevel Info

ConnectPort 443
ConnectPort 563

Upstream http 127.0.0.1:988
EOF

echo "[i] Starting tinyproxy on port ${PROXY_PORT}"
tinyproxy -d
