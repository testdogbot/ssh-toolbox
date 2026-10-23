#!/bin/bash
# ============================================================
# 模块: warp_manager (WARP 管理)
# ============================================================
warp_menu() {
    local script_url script_file
    script_url="https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh"
    script_file=$(mktemp "${TMPDIR:-/tmp}/ssh-toolbox-warp.XXXXXX") || {
        echo "无法创建 WARP 临时文件。" >&2
        return 1
    }

    if ! command -v curl >/dev/null 2>&1; then
        rm -f -- "$script_file"
        echo "缺少 curl，无法获取 WARP 管理脚本。" >&2
        return 1
    fi
    if ! curl --fail --location --silent --show-error --max-time 60 \
        "$script_url" -o "$script_file"; then
        rm -f -- "$script_file"
        echo "下载 WARP 管理脚本失败: ${script_url}" >&2
        return 1
    fi
    if [ ! -s "$script_file" ] || ! bash -n "$script_file"; then
        rm -f -- "$script_file"
        echo "下载的 WARP 管理脚本为空或 Bash 语法检查失败。" >&2
        return 1
    fi

    echo "即将运行第三方 WARP 管理脚本:"
    echo "$script_url"
    if confirm_action "已确认来源并继续运行?"; then
        local result=0
        bash "$script_file" || result=$?
        rm -f -- "$script_file"
        return "$result"
    fi
    rm -f -- "$script_file"
    echo "已取消。"
    return 0
}
