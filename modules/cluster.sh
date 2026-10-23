#!/bin/bash
# ============================================================
# 模块: cluster (服务器集群 SSH 控制)
# ============================================================
cluster_menu() {
    local choice target
    while true; do
        clear
        echo "▶ 服务器集群控制"
        echo "提示：先在 ~/.ssh/config 中为每台服务器配置 Host 别名和密钥。"
        echo "1. 查看 SSH 配置别名"
        echo "2. 连接到 SSH 别名"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1)
                if [ -f "${HOME}/.ssh/config" ]; then
                    awk '$1 == "Host" {for (i=2; i<=NF; i++) if ($i !~ /[*?]/) print $i}' "${HOME}/.ssh/config"
                else
                    echo "未找到 ${HOME}/.ssh/config。"
                fi
                ;;
            2)
                read -r -p "SSH Host 别名: " target
                if [[ "$target" =~ ^[A-Za-z0-9_.@-]+$ ]]; then
                    ssh "$target"
                else
                    echo "Host 别名格式无效。"
                fi
                ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
