#!/bin/bash
# Генерирует секрет в формате Fake TLS (ee + domain + 32hex) для tg:// ссылки
# Использование: ./generate-secret-tls.sh 32hex_secret tls_domain
# Пример: ./generate-secret-tls.sh 56b8c41e614ac0d4d4783f69a58c9229 1c.ru

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Использование: $0 <32_hex_secret> <tls_domain>"
  exit 1
fi

SECRET_32="$1"
DOMAIN="$2"

# Формат: ee + 32hex + len(domain) + domain_in_hex
# domain "1c.ru" = 5 chars = 0x05, hex: 31 63 2e 72 75
DOMAIN_HEX=$(echo -n "$DOMAIN" | od -A n -t x1 | tr -d ' \n')
DOMAIN_LEN=${#DOMAIN}
LEN_HEX=$(printf "%02x" $DOMAIN_LEN)

echo "ee${SECRET_32}${LEN_HEX}${DOMAIN_HEX}"
