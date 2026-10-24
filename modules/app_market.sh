#!/bin/bash
# ============================================================
# 模块: app_market (本地与远程应用)
# ============================================================
app_market_config_file() {
    printf '%s\n' "${HOME}/.config/ssh-toolbox/app-index-url"
}

app_market_index_url() {
    local config_file
    config_file=$(app_market_config_file)
    if [ -r "$config_file" ]; then
        IFS= read -r REPLY < "$config_file" || true
    else
        REPLY=""
    fi
}

app_market_valid_https_url() {
    local authority host octet port_value
    local -a octets
    [[ "$1" =~ ^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[A-Za-z0-9._~/%+-]*)?$ && "$1" != *'..'* && "$1" != *'?'* && "$1" != *'#'* && "$1" != *'@'* ]] || return 1
    authority="${1#https://}"
    authority="${authority%%/*}"
    if [[ "$authority" == *:* ]]; then
        port_value="${authority##*:}"
        [[ "$port_value" =~ ^[0-9]{1,5}$ ]] && [ "$port_value" -ge 1 ] && [ "$port_value" -le 65535 ] || return 1
    fi
    host="${authority%%:*}"
    if [[ "$host" =~ ^[0-9.]+$ ]]; then
        [[ "$host" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
        IFS=. read -r -a octets <<< "$host"
        for octet in "${octets[@]}"; do
            [[ "$octet" =~ ^[0-9]{1,3}$ ]] && [ "$octet" -le 255 ] || return 1
        done
    fi
    return 0
}

app_market_set_index_url() {
    local url config_file temp_file
    read -r -p "远程 TSV 索引 HTTPS URL: " url
    app_market_valid_https_url "$url" || { echo "仅允许无凭据的 HTTPS URL。" >&2; return 1; }
    config_file=$(app_market_config_file)
    mkdir -p "$(dirname "$config_file")" || return 1
    temp_file=$(mktemp "$(dirname "$config_file")/.app-index-url.XXXXXX") || return 1
    (umask 077; printf '%s\n' "$url" > "$temp_file") || { rm -f -- "$temp_file"; return 1; }
    mv -f -- "$temp_file" "$config_file" || { rm -f -- "$temp_file"; return 1; }
    echo "远程索引 URL 已保存。"
}

app_market_fetch() {
    local url="$1" output="$2" http_status
    http_status=$(curl --fail --silent --show-error --proto '=https' --tlsv1.2 \
        --max-filesize 1048576 --connect-timeout 10 --max-time 30 \
        --output "$output" --write-out '%{http_code}' "$url") || return 1
    [ "$http_status" = "200" ]
}

app_market_list_remote() {
    local index_url temp_file name version path digest index_size
    app_market_index_url
    index_url="$REPLY"
    app_market_valid_https_url "$index_url" || { echo "未配置有效的 HTTPS 索引 URL。"; return 1; }
    temp_file=$(mktemp "${TMPDIR:-/tmp}/ssh-toolbox-index.XXXXXX") || return 1
    if ! app_market_fetch "$index_url" "$temp_file"; then
        rm -f -- "$temp_file"
        echo "下载远程索引失败。" >&2
        return 1
    fi
    index_size=$(wc -c < "$temp_file")
    if [ "$index_size" -gt 1048576 ]; then
        rm -f -- "$temp_file"
        echo "远程索引超过 1 MiB。" >&2
        return 1
    fi
    while IFS=$'\t' read -r name version path digest; do
        [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$ && "$version" =~ ^[A-Za-z0-9][A-Za-z0-9_.+-]{0,31}$ && "$path" =~ ^[A-Za-z0-9][A-Za-z0-9_./-]{0,199}\.sh$ && "$path" != /* && "$path" != *'..'* && "$digest" =~ ^[a-fA-F0-9]{64}$ ]] || continue
        printf '%s\t%s\t%s\t%s\n' "$name" "$version" "$path" "$digest"
    done < "$temp_file"
    rm -f -- "$temp_file"
}

app_market_download_remote() {
    local selection index=0 row name version path digest base_url file_url app_dir target source_target source_temp temp_file actual_digest
    local -a entries=()
    while IFS= read -r row; do
        [ -n "$row" ] && entries+=("$row")
    done < <(app_market_list_remote)
    if [ "${#entries[@]}" -eq 0 ]; then
        echo "索引没有有效应用条目。"
        return 1
    fi
    for row in "${entries[@]}"; do
        IFS=$'\t' read -r name version path digest <<< "$row"
        printf '%2d. %s (%s)\n' "$((++index))" "$name" "$version"
    done
    read -r -p "选择要下载的应用编号: " selection
    [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#entries[@]}" ] || { echo "无效编号。"; return 1; }
    IFS=$'\t' read -r name version path digest <<< "${entries[$((selection - 1))]}"
    app_market_index_url
    base_url="${REPLY%/*}/"
    file_url="${base_url}${path}"
    app_market_valid_https_url "$file_url" || return 1
    app_dir="${SCRIPT_DIR}/apps"
    target="${app_dir}/${name}-${version}.sh"
    source_target="${target}.source"
    [ ! -L "$app_dir" ] || { echo "apps/ 不能是符号链接，拒绝写入。" >&2; return 1; }
    mkdir -p "$app_dir" || return 1
    [ -d "$app_dir" ] && [ ! -L "$app_dir" ] || { echo "apps/ 目录无效，拒绝写入。" >&2; return 1; }
    [ ! -e "$target" ] && [ ! -L "$target" ] && [ ! -e "$source_target" ] && [ ! -L "$source_target" ] || { echo "目标文件或来源记录已存在，拒绝覆盖：${target}" >&2; return 1; }
    temp_file=$(mktemp "${app_dir}/.download.XXXXXX") || return 1
    if ! app_market_fetch "$file_url" "$temp_file" || [ "$(wc -c < "$temp_file")" -gt 1048576 ]; then
        rm -f -- "$temp_file"
        echo "下载失败或文件超过 1 MiB。" >&2
        return 1
    fi
    actual_digest=$(sha256sum "$temp_file" | awk '{print $1}') || { rm -f -- "$temp_file"; return 1; }
    if [ "${actual_digest,,}" != "${digest,,}" ] || ! bash -n "$temp_file"; then
        rm -f -- "$temp_file"
        echo "SHA-256 或 Bash 语法校验失败。" >&2
        return 1
    fi
    chmod 600 "$temp_file" || { rm -f -- "$temp_file"; return 1; }
    source_temp=$(mktemp "${app_dir}/.source.XXXXXX") || { rm -f -- "$temp_file"; return 1; }
    printf 'name=%s\nversion=%s\nurl=%s\nsha256=%s\n' "$name" "$version" "$file_url" "$digest" > "$source_temp" || {
        rm -f -- "$temp_file" "$source_temp"
        return 1
    }
    chmod 600 "$source_temp" || { rm -f -- "$temp_file" "$source_temp"; return 1; }
    if ! ln -- "$temp_file" "$target"; then
        rm -f -- "$temp_file" "$source_temp"
        echo "目标文件已存在或无法安全创建，拒绝覆盖。" >&2
        return 1
    fi
    if ! ln -- "$source_temp" "$source_target"; then
        rm -f -- "$target" "$temp_file" "$source_temp"
        echo "无法安全保存来源记录，已移除未登记脚本。" >&2
        return 1
    fi
    rm -f -- "$temp_file" "$source_temp"
    echo "已下载并校验 ${name} ${version}：${target}。来源：${file_url}。脚本尚未执行。"
}

app_market_menu() {
    local app_dir script_dir selected_index script_path index choice source_info
    local -a scripts
    clear
    echo "▶ $(t app_market_title '本地与远程应用市场')"
    echo "1. $(t app_market_local '本地应用与辅助脚本')"
    echo "2. $(t app_market_remote '浏览远程应用目录')"
    echo "3. $(t app_market_set_index '设置远程索引 URL')"
    echo "4. $(t app_market_download '下载远程应用（不会自动运行）')"
    echo "0. 返回"
    read -r -p "请选择: " choice
    case "$choice" in
        2) app_market_list_remote; return $? ;;
        3) app_market_set_index_url; return $? ;;
        4) app_market_download_remote; return $? ;;
        0|'') return 0 ;;
        1) ;;
        *) echo "无效的输入。"; return 1 ;;
    esac
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
    echo "▶ $(t app_market_local '本地应用与辅助脚本')"
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
    if [ -r "${script_path}.source" ]; then
        source_info=$(sed -n 's/^url=//p' "${script_path}.source" | head -n 1)
        echo "远程脚本来源：${source_info:-未记录}"
    else
        echo "本地脚本：${script_path#"$SCRIPT_DIR"/}"
    fi
    confirm_action "运行该脚本 ${script_path#"$SCRIPT_DIR"/}?" || return 0
    bash "$script_path"
}
