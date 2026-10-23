#!/bin/bash
# ============================================================
# 模块: app_market (应用市场)
# ============================================================
app_market_menu() {
    local app
    clear
    echo "▶ 本地应用市场"
    if [ ! -d "${SCRIPT_DIR}/apps" ]; then
        echo "apps/ 目录不存在。"
        return 1
    fi
    find "${SCRIPT_DIR}/apps" -maxdepth 1 -type f -print
    app=""
    read -r -p "输入本地脚本文件名运行，或直接回车返回: " app
    [ -n "$app" ] || return 0
    if [[ "$app" != "$(basename "$app")" || ! -f "${SCRIPT_DIR}/apps/${app}" ]]; then
        echo "无效的应用文件。"
        return 1
    fi
    confirm_action "运行本地应用 ${app}?" || return 0
    case "$app" in
        *.sh) bash "${SCRIPT_DIR}/apps/${app}" ;;
        *) echo "仅允许运行 .sh 文件。" ; return 1 ;;
    esac
}
