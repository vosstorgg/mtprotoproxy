#!/bin/bash
# Выводит ссылки для клиента: мобильные (Fake TLS) и Desktop (классический)
# Использование: ./get-link.sh company_name [SERVER_IP]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="${PROJECT_DIR}/telemt.toml"

if [ -z "$1" ]; then
  echo "Использование: $0 <company_name> [SERVER_IP]"
  echo "Пример: $0 acme_corp"
  exit 1
fi

CLIENT_ID="${1//[^a-zA-Z0-9_]/_}"
CLIENT_ID="${CLIENT_ID,,}"

if [ ! -f "$CONFIG" ]; then
  echo "Ошибка: $CONFIG не найден"
  exit 1
fi

SECRET_32=$(grep -E "^${CLIENT_ID} = " "$CONFIG" | sed -E 's/.*= *"([^"]+)".*/\1/')

if [ -z "$SECRET_32" ]; then
  echo "Ошибка: клиент '$CLIENT_ID' не найден в конфиге"
  exit 1
fi

# Fake TLS (ee): для мобильных, работает при tls=true
TLS_DOMAIN=$(grep -E "tls_domain" "$CONFIG" | grep -v -E "^\s*#" | sed -E 's/.*tls_domain *= *"([^"]+)".*/\1/' | head -1)
if [ -n "$TLS_DOMAIN" ]; then
  DOMAIN_HEX=$(echo -n "$TLS_DOMAIN" | od -A n -t x1 | tr -d ' \n')
  LEN_HEX=$(printf "%02x" ${#TLS_DOMAIN})
  SECRET_TLS="ee${SECRET_32}${LEN_HEX}${DOMAIN_HEX}"
else
  SECRET_TLS="$SECRET_32"
fi

if [ -n "$2" ]; then
  SERVER_IP="$2"
else
  SERVER_IP=$(grep -E "announce_ip" "$CONFIG" | grep -v -E "^\s*#" | sed -E 's/.*announce_ip *= *"([^"]+)".*/\1/' | head -1)
  if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null || curl -s --connect-timeout 2 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
  fi
fi

PORT=443

echo "Клиент: $CLIENT_ID"
echo "Сервер: $SERVER_IP:$PORT"
echo ""
echo "=== Мобильные (Fake TLS) ==="
echo "https://t.me/proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET_TLS}"
echo "tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET_TLS}"
echo ""
echo "=== Desktop (классический) ==="
echo "https://t.me/proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET_32}"
echo "tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET_32}"
