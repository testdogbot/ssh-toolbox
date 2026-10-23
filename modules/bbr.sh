#!/bin/bash
# ============================================================
# 模块: bbr (TCP 拥塞控制)
# ============================================================
bbr_status() {
    printf '当前拥塞控制: '
    cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "不可用"
    printf '可用算法: '
    cat /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null || echo "未知"
}

bbr_enable() {
    local available
    available=$(cat /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null)
    if ! grep -qw bbr <<<"$available"; then
        echo "当前内核未提供 BBR；请使用支持 BBR 的内核后重试。"
        return 1
    fi
    mkdir -p /etc/sysctl.d
    printf 'net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr\n' > /etc/sysctl.d/99-toolbox-bbr.conf
    sysctl --system
}

bbr_disable() {
    if [ ! -f /etc/sysctl.d/99-toolbox-bbr.conf ]; then
        echo "未找到本工具创建的 BBR 配置。"
        return 1
    fi
    rm -f /etc/sysctl.d/99-toolbox-bbr.conf
    sysctl -w net.ipv4.tcp_congestion_control=cubic
}

bbrv3() {
    echo "BBRv3 需要专门的内核；本项目不会自动下载或替换系统内核。"
    echo "当前内核: $(uname -r)"
}

bbr_menu() {
    local choice
    while true; do
        clear
        echo "▶ BBR 加速管理"
        echo "1. 查看状态"
        echo "2. 启用内核自带 BBR"
        echo "3. 恢复 cubic（仅移除本工具配置）"
        echo "4. BBRv3 说明"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1) bbr_status ;;
            2) confirm_action "写入 sysctl 配置并启用 BBR?" && bbr_enable ;;
            3) confirm_action "移除本工具 BBR 配置并切换到 cubic?" && bbr_disable ;;
            4) bbrv3 ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
