#!/bin/bash
# Выводит tg:// и https:// ссылки для клиента
# Использование: ./get-link.sh company_name [SERVER_IP]
# SERVER_IP — опционально, иначе определяется автоматически

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

SECRET=$(grep -E "^${CLIENT_ID} = " "$CONFIG" | sed -E 's/.*= *"([^"]+)".*/\1/')

if [ -z "$SECRET" ]; then
  echo "Ошибка: клиент '$CLIENT_ID' не найден в конфиге"
  exit 1
fi

if [ -n "$2" ]; then
  SERVER_IP="$2"
else
  # Пробуем announce_ip из конфига
  SERVER_IP=$(grep -E "announce_ip" "$CONFIG" | sed -E 's/.*announce_ip *= *"([^"]+)".*/\1/' | head -1)
  if [ -z "$SERVER_IP" ]; then
    # Автоопределение (работает на VPS)
    SERVER_IP=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null || curl -s --connect-timeout 2 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
  fi
fi

PORT=443

echo "Клиент: $CLIENT_ID"
echo "Сервер: $SERVER_IP:$PORT"
echo ""
echo "tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET}"
echo "https://t.me/proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET}"
