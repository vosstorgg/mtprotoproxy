#!/bin/bash
# Добавляет нового клиента в telemt.toml
# Использование: ./add-client.sh company_name
# Пример: ./add-client.sh acme_corp

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="${PROJECT_DIR}/telemt.toml"

if [ -z "$1" ]; then
  echo "Использование: $0 <company_name>"
  echo "Пример: $0 acme_corp"
  exit 1
fi

CLIENT_ID="${1//[^a-zA-Z0-9_]/_}"
CLIENT_ID="${CLIENT_ID,,}"

if [ ! -f "$CONFIG" ]; then
  echo "Ошибка: $CONFIG не найден. Скопируйте telemt.toml.example в telemt.toml"
  exit 1
fi

if grep -q "^${CLIENT_ID} = " "$CONFIG" 2>/dev/null; then
  echo "Клиент '$CLIENT_ID' уже существует в конфиге"
  exit 1
fi

SECRET=$(openssl rand -hex 16)
NEW_LINE="${CLIENT_ID} = \"${SECRET}\""

# Вставляем новую строку перед [[upstreams]]
awk -v line="$NEW_LINE" '
  /^\[\[upstreams\]\]/ && !inserted { print line; inserted=1 }
  { print }
' "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"

echo "✓ Клиент '$CLIENT_ID' добавлен"
echo ""
echo "Секрет: $SECRET"
echo ""
echo "Ссылки (подставьте ваш IP):"
echo "  tg://proxy?server=YOUR_IP&port=443&secret=${SECRET}"
echo "  https://t.me/proxy?server=YOUR_IP&port=443&secret=${SECRET}"
echo ""
echo "Или выполните: ./scripts/get-link.sh $CLIENT_ID"
