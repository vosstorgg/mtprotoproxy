# Развёртывание MTProxy B2B

Инструкция по развёртыванию Telemt (MTProxy с Fake TLS) на VPS.

## С нуля (переустановка ОС)

Если сервер не жалко и хотите начать с чистого листа:

1. **Панель VPS** (Hetzner Cloud, DigitalOcean, Timeweb и т.п.) → **Reinstall** / **Переустановить** → выберите **Ubuntu 24.04** или **Debian 12**.
2. Дождитесь загрузки, подключитесь по SSH.
3. Выполните шаги ниже начиная с [Шаг 1](#шаг-1-подготовка-сервера).

---

## Требования

- **VPS** с Ubuntu/Debian (рекомендуется 512 MB RAM+)
- **Docker** и Docker Compose
- **Порт 443** свободен (остановите Nginx/Apache, если есть)

## Шаг 1. Подготовка сервера

```bash
# Установка Docker (если нет)
curl -fsSL https://get.docker.com | sh

# Проверка порта 443
ss -tulpn | grep 443
# Если занят: systemctl stop nginx
```

## Шаг 2. Клонирование и настройка

```bash
# Клонируйте репозиторий или скопируйте файлы на сервер
cd /opt/mtprotoproxy  # или ваш путь

# Создайте конфиг из шаблона
cp telemt.toml.example telemt.toml

# Опционально: укажите announce_ip (ваш публичный IP) в telemt.toml
# В секции [[server.listeners]] раскомментируйте:
# announce_ip = "1.2.3.4"
```

## Шаг 3. Добавление первого клиента

```bash
chmod +x scripts/*.sh

./scripts/add-client.sh demo
# Скрипт выведет секрет и ссылки
```

## Шаг 4. Запуск

```bash
docker compose up -d

# Проверка
docker compose ps
docker compose logs -f
```

## Шаг 5. Firewall

Убедитесь, что порт 443 открыт:

```bash
# ufw (Ubuntu)
ufw allow 443/tcp
ufw reload

# firewalld
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
```

## Управление клиентами

### Добавить клиента
```bash
./scripts/add-client.sh company_name
```

### Получить ссылки для клиента
```bash
./scripts/get-link.sh company_name
```
Скрипт выведет обе ссылки: для мобильных (Fake TLS) и для Desktop (классический).

### Перезапуск после изменения конфига
```bash
docker compose restart
```

## Telegram Desktop: «doesn't support this proxy type»

1. **Обновите** Telegram Desktop до последней версии: https://desktop.telegram.org/
2. Используйте ссылку из блока «Desktop (классический)» — она работает при `classic = true` в конфиге

## Чеклист перед продакшеном

- [ ] `telemt.toml` создан из `telemt.toml.example`
- [ ] `announce_ip` указан (ваш публичный IP)
- [ ] chmod +x scripts/*.sh — после git pull
- [ ] `classic = true` и `tls = true` — обе ссылки (мобильные + Desktop) работают для одного клиента
- [ ] Домен маскировки в `tls_domain` (по умолчанию `1c.ru`)
- [ ] Добавлен минимум один клиент
- [ ] Порт 443 открыт в firewall
