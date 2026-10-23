#!/bin/bash
# ============================================================
# 模块: kpanel (KPanel)
# ============================================================
kpanel_menu() {
    local choice
    while true; do
        clear
        echo "▶ KPanel Web 面板"
        echo "1. 检查 KPanel 容器"
        echo "2. 查看部署状态说明"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1)
                if command -v docker >/dev/null 2>&1; then
                    docker ps -a --filter name=kpanel
                else
                    echo "未安装 Docker。"
                fi
                ;;
            2)
                echo "当前项目未包含经过验证的 KPanel 部署模板或安装器。"
                echo "为避免覆盖现有服务，此入口暂不自动部署；请使用 KPanel 官方说明。"
            ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
