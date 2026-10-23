#!/bin/bash
# ============================================================
# 模块: system_info (系统信息)
# ============================================================
system_info() {
    clear
    local os_name cpu_count mem_total disk_info local_ip
    os_name=$(. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-未知系统}")
    cpu_count=$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '未知')
    mem_total=$(awk '/MemTotal/ {printf "%.1f GiB", $2 / 1048576}' /proc/meminfo 2>/dev/null)
    disk_info=$(df -hP / 2>/dev/null | awk 'NR==2 {printf "%s / %s（已用 %s）", $3, $2, $5}')
    local_ip=$(hostname -I 2>/dev/null | awk '{print $1}')

    printf '系统: %s\n' "$os_name"
    printf '内核: %s\n' "$(uname -srmo 2>/dev/null)"
    printf 'CPU: %s 核\n' "$cpu_count"
    printf '内存总量: %s\n' "${mem_total:-未知}"
    printf '根分区: %s\n' "${disk_info:-未知}"
    printf '本机 IP: %s\n' "${local_ip:-未知}"
    printf '运行时间: %s\n' "$(uptime -p 2>/dev/null || uptime 2>/dev/null)"
}
