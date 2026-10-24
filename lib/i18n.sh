#!/bin/bash
#=========================================================================
# lib/i18n.sh - 多语言支持
# 整合自 kejilion/sh 的多语言架构
# 支持语言: cn(简中) en(英文) jp(日文) kr(韩文) ru(俄文) ir(波斯) tw(繁中)
#=========================================================================

# 当前语言 (默认中文)
CURRENT_LANG="cn"

# 设置语言；仅接受本项目实际提供的翻译包。
set_language() {
    local lang="$1" lang_file
    case "$lang" in cn|en) ;; *) CURRENT_LANG="cn"; return 1 ;; esac
    lang_file="${SCRIPT_DIR}/i18n/${lang}/messages.sh"
    [ -r "$lang_file" ] || { CURRENT_LANG="cn"; return 1; }
    CURRENT_LANG="$lang"
}

language_config_file() {
    printf '%s\n' "${HOME}/.config/ssh-toolbox/language"
}

save_language() {
    local lang="$1" config_file temp_file
    set_language "$lang" || return 1
    config_file=$(language_config_file)
    mkdir -p "$(dirname "$config_file")" || return 1
    temp_file=$(mktemp "$(dirname "$config_file")/.language.XXXXXX") || return 1
    (umask 077; printf '%s\n' "$CURRENT_LANG" > "$temp_file") || { rm -f -- "$temp_file"; return 1; }
    mv -f -- "$temp_file" "$config_file" || { rm -f -- "$temp_file"; return 1; }
}

load_language() {
    local config_file saved_lang
    if [ -n "${SSH_TOOLBOX_LANG:-}" ]; then
        set_language "$SSH_TOOLBOX_LANG" || CURRENT_LANG="cn"
        return 0
    fi
    config_file=$(language_config_file)
    if [ -r "$config_file" ]; then
        IFS= read -r saved_lang < "$config_file" || true
        set_language "$saved_lang" || CURRENT_LANG="cn"
    else
        detect_language
    fi
}

choose_language() {
    local choice lang
    echo "Language / 语言: 1) 中文  2) English"
    read -r -p "选择 / Select [1-2]: " choice
    case "$choice" in
        1|cn) lang=cn ;;
        2|en) lang=en ;;
        *) echo "Invalid choice; language unchanged."; return 1 ;;
    esac
    save_language "$lang" || { echo "Failed to save language preference." >&2; return 1; }
    echo "语言已设置为 ${lang}。"
}

# 自动检测系统语言
detect_language() {
    local sys_lang
    sys_lang=$(echo "${LANG:-}" | cut -d'.' -f1 | cut -d'_' -f1)
    case "$sys_lang" in
        zh*) CURRENT_LANG="cn" ;;
        en*) CURRENT_LANG="en" ;;
        *) CURRENT_LANG="cn" ;;
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
load_language
