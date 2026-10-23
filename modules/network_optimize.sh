#!/bin/bash
# ============================================================
# 模块: network_optimize (网络优化)
# ============================================================
network_optimize_menu() {
    local choice
    while true; do
        clear
        echo "▶ 网络优化"
        echo "1. 运行网络优化工具"
        echo "2. 检查压缩算法配置说明"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1)
                if [ -f "${SCRIPTS_DIR}/network-optimize.sh" ]; then
                    bash "${SCRIPTS_DIR}/network-optimize.sh"
                else
                    echo "找不到 scripts/network-optimize.sh。"
                fi
                ;;
            2)
                echo "Brotli/Zstd/Gzip 通常由 Web 服务器或反向代理配置。"
                echo "请先备份现有配置，并在修改后使用对应服务的配置检查命令。"
                ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
