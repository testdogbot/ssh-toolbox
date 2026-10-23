#!/bin/bash
# ============================================================
# 模块: ldnmp (LDNMP 建站)
# ============================================================
ldnmp_menu() {
    clear
    echo "LDNMP 安装脚本会修改系统软件、Docker 服务及 iptables 默认策略。"
    echo "仅建议在全新 Debian/Ubuntu 服务器运行；请先备份数据并确认防火墙规则。"
    if [ ! -f "${SCRIPTS_DIR}/ldnmp.sh" ]; then
        echo "找不到 scripts/ldnmp.sh。"
        return 1
    fi
    confirm_action "确认启动 LDNMP 安装脚本?" || return 0
    bash "${SCRIPTS_DIR}/ldnmp.sh"
}
