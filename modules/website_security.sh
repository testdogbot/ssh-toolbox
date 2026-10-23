#!/bin/bash
# ============================================================
# 模块: website_security (网站安全)
# ============================================================
fail2ban_panel() {
    if ! command -v fail2ban-client >/dev/null 2>&1; then
        echo "Fail2ban 未安装。可先使用系统包管理器安装 fail2ban。"
        return 1
    fi
    fail2ban-client status
}

website_security_menu() {
    local choice
    while true; do
        clear
        echo "▶ 网站安全"
        echo "1. 查看 Fail2ban 状态"
        echo "2. Fail2ban 服务状态"
        echo "3. Cloudflare Under Attack 模式脚本（需自行核实配置）"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1) fail2ban_panel ;;
            2) systemctl status fail2ban ;;
            3)
                if [ -f "${SCRIPTS_DIR}/CF-Under-Attack.sh" ] &&
                    confirm_action "运行本地 Cloudflare 脚本?" ; then
                    bash "${SCRIPTS_DIR}/CF-Under-Attack.sh"
                else
                    echo "已取消或找不到脚本。"
                fi
                ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
