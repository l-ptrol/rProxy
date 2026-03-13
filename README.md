# 🔄 rProxy

**Менеджер обратного прокси для роутеров Keenetic**

Публикация локальных сервисов в интернет через VPS с nginx в качестве reverse proxy.

```
[LAN сервис] ← [Keenetic] ══SSH туннель══▶ [VPS:nginx] → Интернет
```

## ⚡ Быстрый старт

### 1. Установка (на роутере Keenetic)

> Требуется [Entware](https://help.keenetic.com/hc/ru/articles/360021214160)

```bash
curl -sSL http://5.104.75.50:3000/Petro1990/rProxy/raw/branch/main/install.sh | sh
```

### 2. Настройка VPS

```bash
rproxy setup
```

Скрипт запросит:
- **IP-адрес VPS** — адрес вашего сервера
- **SSH порт** — порт SSH (по умолчанию 22)
- **SSH пользователь** — логин (по умолчанию root)
- **Метод авторизации** — SSH-ключ или пароль

При выборе SSH-ключа скрипт автоматически сгенерирует ключ и скопирует его на VPS. Также будет автоматически установлен и настроен nginx.

### 3. Публикация сервиса

**С доменом** (порт 80):
```bash
rproxy add nas 192.168.1.100:5000 --domain nas.example.com
```

**Без домена** (произвольный порт):
```bash
rproxy add camera 192.168.1.50:8080 --port 9090
```

**С автоподбором порта:**
```bash
rproxy add homeassistant 192.168.1.10:8123
```

## 📋 Команды

| Команда | Описание |
|---------|----------|
| `rproxy setup` | Настроить подключение к VPS |
| `rproxy add <имя> <хост:порт> [опции]` | Добавить сервис |
| `rproxy remove <имя>` | Удалить сервис |
| `rproxy start [имя]` | Запустить туннель(и) |
| `rproxy stop [имя]` | Остановить туннель(и) |
| `rproxy restart [имя]` | Перезапустить туннель(и) |
| `rproxy status` | Статус всех сервисов |
| `rproxy list` | Краткий список |
| `rproxy enable <имя>` | Включить автозапуск |
| `rproxy disable <имя>` | Выключить автозапуск |
| `rproxy logs <имя>` | Логи nginx на VPS |

### Опции для `add`

| Опция | Описание |
|-------|----------|
| `--domain`, `-d` | Привязать к домену (nginx слушает порт 80) |
| `--port`, `-p` | Указать внешний порт (без домена) |

## 🏗 Архитектура

### На роутере (Keenetic + Entware)
- **autossh** — устанавливает устойчивые reverse SSH-туннели до VPS
- Каждый сервис = отдельный туннель
- Конфигурация: `/opt/etc/rproxy/`
- PID-файлы: `/opt/var/run/rproxy/`

### На VPS
- **nginx** — принимает входящие запросы и проксирует в SSH-туннели
- Конфиги сервисов: `/etc/nginx/sites-enabled/rproxy_*.conf`

### Файлы конфигурации

```
/opt/etc/rproxy/
├── rproxy.conf           # Параметры подключения к VPS
└── services/
    ├── nas.conf           # Конфиг сервиса "nas"
    ├── camera.conf        # Конфиг сервиса "camera"
    └── ...
```

## 🔒 Безопасность

- SSH-ключ хранится в `/opt/etc/rproxy/id_rsa` (права 600)
- Пароль VPS хранится в `/opt/etc/rproxy/rproxy.conf` (права 600)
- Все соединения зашифрованы через SSH

> **Рекомендация:** используйте авторизацию по SSH-ключу для лучшей безопасности.

## 🔧 Решение проблем

### Туннель не подключается
```bash
# Проверьте статус
rproxy status

# Перезапустите туннель
rproxy restart <имя>

# Проверьте SSH-подключение вручную
ssh -i /opt/etc/rproxy/id_rsa -p 22 root@<VPS_IP>
```

### Сервис не доступен по домену
- Убедитесь, что DNS-запись домена указывает на IP VPS
- Проверьте логи: `rproxy logs <имя>`
- Проверьте nginx на VPS: `ssh root@VPS 'nginx -t'`

### Автозапуск не работает
```bash
# Проверьте init-скрипт
ls -la /opt/etc/init.d/S98rproxy

# Проверьте, что сервис enabled
rproxy list
```

## 📦 Требования

### Роутер
- Keenetic с установленным [Entware](https://help.keenetic.com/hc/ru/articles/360021214160)
- Пакеты: `openssh-client`, `autossh`, `curl`, `sshpass`

### VPS
- Linux (Debian/Ubuntu/CentOS)
- nginx (устанавливается автоматически при `setup`)
- SSH-доступ

## 📝 Лицензия

MIT
