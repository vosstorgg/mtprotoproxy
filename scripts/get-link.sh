#!/bin/bash
# Выводит tg:// и https:// ссылки для клиента
# Использование: ./get-link.sh company_name [SERVER_IP]
# Опции: --classic — только 32 hex (без ee), для совместимости с Telegram Desktop
# SERVER_IP — опционально, иначе определяется автоматически

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="${PROJECT_DIR}/telemt.toml"
CLASSIC_MODE=false

if [ "$1" = "--classic" ]; then
  CLASSIC_MODE=true
  shift
fi

if [ -z "$1" ]; then
  echo "Использование: $0 [--classic] <company_name> [SERVER_IP]"
  echo "  --classic  — формат без ee (для Telegram Desktop при проблемах с Fake TLS)"
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

# Для Fake TLS (tls=true) нужен формат ee+secret+domain в tg:// ссылке
# Формат: ee + 16 bytes secret + 1 byte len + domain bytes (см. MTProxy protocol)
# --classic: только 32 hex (для Desktop при ошибке "doesn't support this proxy type")
TLS_DOMAIN=$(grep -E "tls_domain" "$CONFIG" | grep -v -E "^\s*#" | sed -E 's/.*tls_domain *= *"([^"]+)".*/\1/' | head -1)
if [ -n "$TLS_DOMAIN" ] && [ "$CLASSIC_MODE" = false ]; then
  DOMAIN_HEX=$(echo -n "$TLS_DOMAIN" | od -A n -t x1 | tr -d ' \n')
  LEN_HEX=$(printf "%02x" ${#TLS_DOMAIN})
  SECRET="ee${SECRET_32}${LEN_HEX}${DOMAIN_HEX}"
else
  SECRET="$SECRET_32"
fi

if [ -n "$2" ]; then
  SERVER_IP="$2"
else
  # Пробуем announce_ip из конфига (игнорируем закомментированные строки)
  SERVER_IP=$(grep -E "announce_ip" "$CONFIG" | grep -v -E "^\s*#" | sed -E 's/.*announce_ip *= *"([^"]+)".*/\1/' | head -1)
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
if [ "$CLASSIC_MODE" = true ]; then
  echo ""
  echo "⚠ Для --classic в telemt.toml должно быть: classic=true, tls=false"
  echo "  И перезапуск: docker compose restart"
fi
