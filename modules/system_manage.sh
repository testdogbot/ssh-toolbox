#!/bin/bash
# ============================================================
# 模块: system_manage (系统更新与清理)
# ============================================================
system_update() {
    if command -v apt-get >/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    elif command -v dnf >/dev/null 2>&1; then
        dnf upgrade -y
    elif command -v yum >/dev/null 2>&1; then
        yum update -y
    elif command -v apk >/dev/null 2>&1; then
        apk update && apk upgrade
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Syu --noconfirm
    elif command -v zypper >/dev/null 2>&1; then
        zypper refresh && zypper update -y
    else
        echo -e "${gl_hong}未识别到支持的包管理器。${gl_bai}"
        return 1
    fi
}

system_clean() {
    echo "系统清理将移除包管理器缓存及不再需要的依赖；日志最多保留 7 天。"
    confirm_action "继续清理?" || return 0

    if command -v apt-get >/dev/null 2>&1; then
        apt-get autoremove --purge -y && apt-get clean
    elif command -v dnf >/dev/null 2>&1; then
        dnf autoremove -y && dnf clean all
    elif command -v yum >/dev/null 2>&1; then
        yum autoremove -y && yum clean all
    elif command -v apk >/dev/null 2>&1; then
        apk cache clean
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sc --noconfirm
    elif command -v zypper >/dev/null 2>&1; then
        zypper clean --all
    else
        echo -e "${gl_hong}未识别到支持的包管理器。${gl_bai}"
        return 1
    fi
    if command -v journalctl >/dev/null 2>&1; then
        journalctl --vacuum-time=7d
    fi
}
