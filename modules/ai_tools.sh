#!/bin/bash
# ============================================================
# 模块: ai_tools (AI 工具)
# ============================================================
ai_tools_menu() {
    local choice script
    while true; do
        clear
        echo "▶ AI 工具管理"
        echo "1. AI CLI 管理"
        echo "2. DeepSeek Harness 管理"
        echo "3. Hermes 管理"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1) script="ai_cli_manager.sh" ;;
            2) script="deepseek_harness_manager.sh" ;;
            3) script="hermes_manager.sh" ;;
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
