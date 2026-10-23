#!/bin/bash
# ============================================================
# 模块: firewall (iptables 防火墙)
# ============================================================
firewall_valid_port() {
    [[ "$1" =~ ^[0-9]{1,5}$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

firewall_menu() {
    local choice port
    while true; do
        clear
        echo "▶ iptables 防火墙（仅管理 IPv4 INPUT TCP 规则）"
        echo "1. 查看 INPUT 规则"
        echo "2. 放行 TCP 端口"
        echo "3. 删除本工具添加的放行规则"
        echo "4. 拒绝 TCP 端口"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1) iptables -S INPUT ;;
            2|3|4)
                read -r -p "TCP 端口: " port
                if ! firewall_valid_port "$port"; then
                    echo "端口必须为 1 到 65535 的整数。"
                    continue
                fi
                if [ "$choice" = "2" ]; then
                    confirm_action "放行 TCP ${port}?" && {
                        iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null ||
                            iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
                    }
                elif [ "$choice" = "3" ]; then
                    iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null &&
                        confirm_action "删除 TCP ${port} 放行规则?" &&
                        iptables -D INPUT -p tcp --dport "$port" -j ACCEPT
                else
                    confirm_action "拒绝 TCP ${port}（可能中断远程访问）?" &&
                        iptables -I INPUT -p tcp --dport "$port" -j DROP
                fi
                ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
