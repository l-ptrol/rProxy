#!/bin/sh
# rProxy Installer for Keenetic / Netcraze Routers (Entware)
# Usage: curl -sSL https://raw.githubusercontent.com/l-ptrol/rProxy/main/install.sh | sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_URL="https://raw.githubusercontent.com/l-ptrol/rProxy/main"
INSTALL_DIR="/opt/bin"
CONF_DIR="/opt/etc/rproxy"
INIT_DIR="/opt/etc/init.d"

msg()  { printf "${GREEN}▸${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}⚠${NC} %s\n" "$*"; }
err()  { printf "${RED}✖${NC} %s\n" "$*" >&2; }

header() {
    printf "\n"
    printf "${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}${BOLD}║  rProxy — Installer for Keenetic / Netcraze  ║${NC}\n"
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
install_pkg "openssh-keygen"
install_pkg "autossh"
install_pkg "curl"

# sshpass is optional (needed only for password auth, may be missing on some architectures)
if ! opkg list-installed 2>/dev/null | grep -q "^sshpass "; then
    msg "Пытаюсь установить sshpass (необязательно)..."
    opkg install "sshpass" >/dev/null 2>&1 || warn "Пакет sshpass не найден. Авторизация по паролю будет недоступна (только по SSH-ключу)."
fi

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
printf "  Следующий шаг — запустите меню управления:\n"
printf "\n"
printf "    ${CYAN}rproxy${NC}\n"
printf "\n"
printf "  Там вы сможете настроить VPS и добавить первый сервис.\n"
printf "\n"
printf "  Полная справка: ${CYAN}rproxy --help${NC}\n"
printf "\n"
