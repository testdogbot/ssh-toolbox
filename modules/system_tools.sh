#!/bin/bash
# ============================================================
# 模块: system_tools (系统工具)
# ============================================================
sshkey_panel() {
    local key_file
    key_file="${HOME}/.ssh/authorized_keys"
    if [ -f "$key_file" ]; then
        cat "$key_file"
    else
        echo "未找到 ${key_file}"
    fi
}

dd_xitong() {
    echo "系统重装未集成：该操作会销毁服务器数据，请使用云服务商控制台。"
    return 1
}

system_tools_menu() {
    local choice key_line key_type
    while true; do
        clear
        echo "▶ $(t menu_system_tools '系统工具')"
        echo "1. $(t system_tools_ssh_status '查看 SSH 服务状态')"
        echo "2. $(t system_tools_authorized_keys '查看 SSH authorized_keys')"
        echo "3. $(t system_tools_add_ssh_key '添加 SSH 公钥')"
        echo "4. $(t system_tools_ssh_dns '查看 SSH 端口及 DNS')"
        echo "5. $(t system_tools_swap '查看 Swap')"
        echo "6. $(t system_tools_firewall '防火墙管理')"
        echo "7. $(t system_tools_backup '备份与恢复')"
        echo "8. $(t system_tools_reboot '重启服务器')"
        echo "9. $(t system_tools_reinstall '系统重装说明')"
        echo "0. $(t common_back '返回主菜单')"
        read -r -p "请选择: " choice
        case "$choice" in
            1)
                if command -v systemctl >/dev/null 2>&1; then
                    systemctl status sshd 2>/dev/null || systemctl status ssh 2>/dev/null
                else
                    service sshd status 2>/dev/null || service ssh status 2>/dev/null
                fi
                ;;
            2) sshkey_panel ;;
            3)
                read -r -p "粘贴单行 SSH 公钥: " key_line
                key_type=${key_line%% *}
                case "$key_type" in ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521) ;; *)
                    echo "不支持或无效的公钥格式。"
                    continue
                    ;;
                esac
                mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
                touch "${HOME}/.ssh/authorized_keys"
                if grep -Fxq -- "$key_line" "${HOME}/.ssh/authorized_keys"; then
                    echo "该公钥已存在。"
                elif printf '%s\n' "$key_line" | ssh-keygen -lf - >/dev/null 2>&1; then
                    printf '%s\n' "$key_line" >> "${HOME}/.ssh/authorized_keys" &&
                        chmod 600 "${HOME}/.ssh/authorized_keys" &&
                        echo "公钥已添加。"
                else
                    echo "公钥校验失败。"
                fi
                ;;
            4)
                if command -v sshd >/dev/null 2>&1; then
                    sshd -T 2>/dev/null | awk '$1 == "port" {print "SSH 端口: " $2; exit}'
                else
                    echo "未找到 sshd。"
                fi
                cat /etc/resolv.conf
                ;;
            5) (swapon --show; free -h) 2>/dev/null ;;
            6) load_module firewall && firewall_menu ;;
            7) load_module backup_migrate && backup_migrate_menu ;;
            8) confirm_action "立即重启服务器?" && server_reboot ;;
            9) dd_xitong ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
