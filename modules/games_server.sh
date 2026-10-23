#!/bin/bash
# ============================================================
# 模块: games_server (游戏服务器)
# ============================================================
games_server_menu() {
    local choice script
    while true; do
        clear
        echo "▶ 游戏开服脚本"
        echo "1. 幻兽帕鲁服务器管理"
        echo "2. Minecraft 服务器管理"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1) script="palworld.sh" ;;
            2) script="mc.sh" ;;
            0) return 0 ;;
            *) echo "无效的输入。"; break_end; continue ;;
        esac
        if [ -f "${SCRIPTS_DIR}/${script}" ]; then
            bash "${SCRIPTS_DIR}/${script}"
        else
            echo "找不到 scripts/${script}。"
        fi
        break_end
    done
}
