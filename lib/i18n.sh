#!/bin/bash
#=========================================================================
# lib/i18n.sh - 多语言支持
# 整合自 kejilion/sh 的多语言架构
# 支持语言: cn(简中) en(英文) jp(日文) kr(韩文) ru(俄文) ir(波斯) tw(繁中)
#=========================================================================

# 当前语言 (默认中文)
CURRENT_LANG="cn"

# 设置语言
set_language() {
    local lang="$1"
    local lang_dir="${SCRIPT_DIR}/i18n/${lang}"
    if [ -d "$lang_dir" ]; then
        CURRENT_LANG="$lang"
    else
        CURRENT_LANG="cn"
    fi
}

# 自动检测系统语言
detect_language() {
    local sys_lang
    sys_lang=$(echo "${LANG:-}" | cut -d'.' -f1 | cut -d'_' -f1)
    case "$sys_lang" in
        zh) CURRENT_LANG="cn" ;;
        ja) CURRENT_LANG="jp" ;;
        ko) CURRENT_LANG="kr" ;;
        ru) CURRENT_LANG="ru" ;;
        fa) CURRENT_LANG="ir" ;;
        *)  CURRENT_LANG="en" ;;
    esac
}

# 翻译函数
# 用法: t "key"  或  t "key" "default_text"
t() {
    local key="$1"
    local default_text="${2:-$key}"
    local lang_file="${SCRIPT_DIR}/i18n/${CURRENT_LANG}/messages.sh"

    if [ -f "$lang_file" ]; then
        source "$lang_file"
        if [[ ! "$key" =~ ^[a-zA-Z0-9_]+$ ]]; then
            echo "$default_text"
            return 0
        fi
        local variable_name="msg_${key}"
        echo "${!variable_name:-$default_text}"
    else
        echo "$default_text"
    fi
}

# 初始化语言
detect_language
