#!/bin/sh
# rProxy Installer for Keenetic Routers (Entware)
# Usage: curl -sSL http://5.104.75.50:3000/Petro1990/rProxy/raw/branch/main/install.sh | sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

REPO_URL="http://5.104.75.50:3000/Petro1990/rProxy/raw/branch/main"
INSTALL_DIR="/opt/bin"
CONF_DIR="/opt/etc/rproxy"
INIT_DIR="/opt/etc/init.d"

msg()  { printf "${GREEN}▸${NC} %s\n" "$*"; }
err()  { printf "${RED}✖${NC} %s\n" "$*" >&2; }

header() {
    printf "\n"
    printf "${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}${BOLD}║     rProxy — Installer for Keenetic      ║${NC}\n"
    printf "${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}\n"
    printf "\n"
}

header

# ─── Check Entware ───────────────────────────────────────────────────
if [ ! -d "/opt/bin" ] || ! command -v opkg >/dev/null 2>&1; then
    err "Entware не найден!"
    err "Установите Entware на роутер: https://help.keenetic.com/hc/ru/articles/360021214160"
    exit 1
fi

msg "Entware обнаружен ✓"

# ─── Install dependencies ───────────────────────────────────────────
msg "Проверяю зависимости..."

install_pkg() {
    local pkg="$1"
    if ! opkg list-installed 2>/dev/null | grep -q "^$pkg "; then
        msg "Устанавливаю $pkg..."
        opkg update >/dev/null 2>&1
        opkg install "$pkg" || {
            err "Не удалось установить $pkg"
            exit 1
        }
    else
        msg "$pkg уже установлен ✓"
    fi
}

install_pkg "openssh-client"
install_pkg "autossh"
install_pkg "curl"
install_pkg "sshpass"

# ─── Download rproxy script ─────────────────────────────────────────
msg "Скачиваю rproxy..."
curl -sSL "$REPO_URL/rproxy" -o "$INSTALL_DIR/rproxy" || {
    err "Не удалось скачать rproxy"
    exit 1
}
chmod +x "$INSTALL_DIR/rproxy"
msg "rproxy установлен в $INSTALL_DIR/rproxy ✓"

# ─── Download init script ───────────────────────────────────────────
msg "Устанавливаю init-скрипт для автозапуска..."
curl -sSL "$REPO_URL/S98rproxy" -o "$INIT_DIR/S98rproxy" || {
    err "Не удалось скачать init-скрипт"
    exit 1
}
chmod +x "$INIT_DIR/S98rproxy"
msg "Init-скрипт установлен ✓"

# ─── Create directories ─────────────────────────────────────────────
mkdir -p "$CONF_DIR/services"
mkdir -p "/opt/var/run/rproxy"

# ─── Done ────────────────────────────────────────────────────────────
printf "\n"
printf "${GREEN}${BOLD}══════════════════════════════════════════${NC}\n"
printf "${GREEN}${BOLD}  rProxy успешно установлен!${NC}\n"
printf "${GREEN}${BOLD}══════════════════════════════════════════${NC}\n"
printf "\n"
printf "  Следующий шаг — настройте подключение к VPS:\n"
printf "\n"
printf "    ${CYAN}rproxy setup${NC}\n"
printf "\n"
printf "  Затем добавьте сервис:\n"
printf "\n"
printf "    ${CYAN}rproxy add myservice 192.168.1.100:8080 --domain my.domain.com${NC}\n"
printf "    ${CYAN}rproxy add camera 192.168.1.50:554 --port 9554${NC}\n"
printf "\n"
printf "  Полная справка: ${CYAN}rproxy --help${NC}\n"
printf "\n"
