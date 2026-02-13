# MTProxy B2B — MVP

MTProto-прокси с Fake TLS для продажи компаниям. Основа: [telemt-docker](https://github.com/An0nX/telemt-docker).

## Быстрый старт

```bash
cp telemt.toml.example telemt.toml
./scripts/add-client.sh demo
docker compose up -d
./scripts/get-link.sh demo
```

## Структура

```
├── docker-compose.yml    # Запуск Telemt
├── telemt.toml.example   # Шаблон конфига (Fake TLS, tls_domain=1c.ru)
├── scripts/
│   ├── generate-secret.sh  # Генерация секрета
│   ├── add-client.sh       # Добавить клиента в конфиг
│   └── get-link.sh         # Получить tg:// ссылку
├── deploy/README.md      # Инструкция по развёртыванию на VPS
└── docs/
    └── client-instructions.md  # Инструкция для передачи клиентам
```

## Документация

- [Развёртывание на VPS](deploy/README.md)
- [Инструкция для клиентов](docs/client-instructions.md)

## Ограничения MVP

- Один VPS, один инстанс
- Ручное добавление клиентов
- Без биллинга и админ-панели
