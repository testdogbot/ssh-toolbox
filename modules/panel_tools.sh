#!/bin/bash
# ============================================================
# 模块: panel_tools (面板工具)
# ============================================================
panel_tools_menu() {
    local choice
    while true; do
        clear
        echo "▶ 面板工具与应用"
        echo "1. 查看常见面板容器"
        echo "2. 查看本地 apps/ 应用包"
        echo "3. 查看常见面板官方入口"
        echo "4. 打开本地应用市场"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1)
                if command -v docker >/dev/null 2>&1; then
                    docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' |
                        grep -Ei '^(NAMES|.*(1panel|宝塔|bt-panel|alist|npm|casaos|apter|nginx-proxy-manager))' ||
                        echo "未发现常见面板容器。"
                else
                    echo "未安装 Docker。"
                fi
                ;;
            2)
                if [ -d "${SCRIPT_DIR}/apps" ]; then
                    find "${SCRIPT_DIR}/apps" -maxdepth 1 -type f -print
                else
                    echo "apps/ 目录不存在。"
                fi
                ;;
            3)
                echo "1Panel: https://1panel.cn/"
                echo "宝塔面板: https://www.bt.cn/"
                echo "AList: https://alist.nn.ci/"
                echo "CasaOS: https://casaos.io/"
                echo "本工具不直接执行第三方在线安装命令，请在核实来源后按官方文档安装。"
                ;;
            4) load_module app_market && app_market_menu ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
