#!/bin/sh
# rProxy Uninstaller for Keenetic / Netcraze Routers (Entware)
# Usage: curl -sSL https://raw.githubusercontent.com/l-ptrol/rProxy/main/uninstall.sh | sh

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
YELLOW='\033[1;33m'
NC='\033[0m'

msg()  { printf "${GREEN}▸${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}⚠${NC} %s\n" "$*"; }
err()  { printf "${RED}✖${NC} %s\n" "$*" >&2; }

header() {
    printf "\n"
    printf "${RED}${BOLD}╔══════════════════════════════════════════╗${NC}\n"
    printf "${RED}${BOLD}║  rProxy — Uninstaller for Keenetic       ║${NC}\n"
    printf "${RED}${BOLD}╚══════════════════════════════════════════╝${NC}\n"
    printf "\n"
}

header

# ─── Stop and Cleanup ───────────────────────────────────────────────
if [ -x "/opt/bin/rproxy" ]; then
    msg "Остановка всех сервисов rProxy..."
    /opt/bin/rproxy stop >/dev/null 2>&1 || true
fi

msg "Удаление файлов..."
rm -f "/opt/bin/rproxy"
rm -f "/opt/etc/init.d/S98rproxy"
rm -f "/opt/etc/init.d/S99rproxy"

if [ -d "/opt/etc/rproxy" ]; then
    printf "  Удалить директорию конфигураций со всеми ключами и сервисами? (/opt/etc/rproxy) (y/n) [n]: "
    # Читаем именно из терминала, чтобы не поглощать код скрипта при curl | sh
    if [ -t 0 ]; then
        read -r ans
    else
        read -r ans < /dev/tty 2>/dev/null || ans="n"
    fi

    if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
        rm -rf "/opt/etc/rproxy"
        msg "Директория конфигураций удалена."
    else
        warn "Конфигурации сохранены в /opt/etc/rproxy."
    fi
fi

rm -rf "/opt/var/run/rproxy"

printf "\n"
printf "${GREEN}${BOLD}══════════════════════════════════════════${NC}\n"
printf "${GREEN}${BOLD}  rProxy успешно удален!${NC}\n"
printf "${GREEN}${BOLD}══════════════════════════════════════════${NC}\n"
printf "\n"
