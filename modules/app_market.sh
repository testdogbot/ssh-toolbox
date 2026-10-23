#!/bin/bash
# ============================================================
# 模块: app_market (本地应用与辅助脚本)
# ============================================================
app_market_menu() {
    local app_dir script_dir selected_index script_path index
    local -a scripts
    app_dir="${SCRIPT_DIR}/apps"
    script_dir="${SCRIPT_DIR}/scripts"
    scripts=()

    if [ -d "$app_dir" ]; then
        while IFS= read -r -d '' script_path; do
            scripts+=("$script_path")
        done < <(find "$app_dir" -maxdepth 1 -type f -name '*.sh' -print0)
    fi
    if [ -d "$script_dir" ]; then
        while IFS= read -r -d '' script_path; do
            scripts+=("$script_path")
        done < <(find "$script_dir" -maxdepth 1 -type f -name '*.sh' -print0)
    fi

    clear
    echo "▶ 本地应用与辅助脚本"
    if [ "${#scripts[@]}" -eq 0 ]; then
        echo "未发现可运行的 .sh 脚本（apps/ 和 scripts/ 均为空）。"
        return 0
    fi
    for index in "${!scripts[@]}"; do
        printf '%2d. %s\n' "$((index + 1))" "${scripts[$index]#"$SCRIPT_DIR"/}"
    done
    read -r -p "输入脚本编号运行，或直接回车返回: " selected_index
    [ -n "$selected_index" ] || return 0
    if ! [[ "$selected_index" =~ ^[0-9]+$ ]] ||
        [ "$selected_index" -lt 1 ] ||
        [ "$selected_index" -gt "${#scripts[@]}" ]; then
        echo "无效的脚本编号。" >&2
        return 1
    fi
    script_path="${scripts[$((selected_index - 1))]}"
    confirm_action "运行本地脚本 ${script_path#"$SCRIPT_DIR"/}?" || return 0
    bash "$script_path"
}
