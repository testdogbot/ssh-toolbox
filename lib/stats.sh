#!/bin/bash
#=========================================================================
# lib/stats.sh - 统计功能 (可选关闭)
# 整合自 kejilion/sh
# 记录脚本版本、使用时间、系统版本、CPU架构、机器所在国家和功能名称
# 不涉及任何敏感信息，可通过 ENABLE_STATS="false" 关闭
#=========================================================================

# 统计开关，默认关闭以尊重用户隐私
ENABLE_STATS="false"

send_stats() {
    if [ "$ENABLE_STATS" == "false" ]; then
        return
    fi

    local country os_info cpu_arch
    country=$(curl -s --max-time 3 ipinfo.io/country 2>/dev/null)
    os_info=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d '=' -f2 | tr -d '"')
    cpu_arch=$(uname -m)

    (
        curl -s -X POST "https://api.kejilion.pro/api/log" \
            -H "Content-Type: application/json" \
            -d "{\"action\":\"$1\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\",\"version\":\"$TOOLBOX_VERSION\"}" \
        &>/dev/null
    ) &
}

# 运行次数统计 (来自 ssh_tool)
sum_run_times() {
    local COUNT TODAY TOTAL
    if [ "$ENABLE_STATS" != "true" ]; then
        STATS_TODAY=0
        STATS_TOTAL=0
        return
    fi

    COUNT=$(curl -s -m 2 "https://count.eooce.dpdns.org/?url=https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh" 2>/dev/null)
    TODAY=$(echo "$COUNT" | sed -n 's/.*"daily_count": \([0-9]\+\).*/\1/p' 2>/dev/null)
    TOTAL=$(echo "$COUNT" | sed -n 's/.*"total_count": \([0-9]\+\).*/\1/p' 2>/dev/null)
    STATS_TODAY="${TODAY:-0}"
    STATS_TOTAL="${TOTAL:-0}"
}
