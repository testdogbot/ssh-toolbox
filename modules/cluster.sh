#!/bin/bash
# ============================================================
# 模块: cluster (服务器集群 SSH 控制)
# ============================================================
cluster_list_aliases() {
    local config_file="${HOME}/.ssh/config"
    [ -f "$config_file" ] || return 1
    awk '
        tolower($1) == "host" {
            for (i = 2; i <= NF; i++) {
                if ($i ~ /[*?]/) continue
                if (!seen[$i]++) print $i
            }
        }
    ' "$config_file"
}

cluster_alias_exists() {
    local requested="$1" alias
    [[ "$requested" =~ ^[A-Za-z0-9_.@-]+$ ]] || return 1
    while IFS= read -r alias; do
        [ "$alias" = "$requested" ] && return 0
    done < <(cluster_list_aliases)
    return 1
}

cluster_probe_alias() (
    local target="$1" probe_dir control_socket
    if ! cluster_alias_exists "$target"; then
        echo "SSH 配置中不存在该别名或别名格式无效。"
        return 1
    fi
    command -v ssh >/dev/null 2>&1 || {
        echo "未找到 ssh 命令。"
        return 1
    }
    probe_dir=$(mktemp -d "${TMPDIR:-/tmp}/ssh-toolbox-probe.XXXXXX") || return 1
    chmod 700 "$probe_dir" || { rm -rf -- "$probe_dir"; return 1; }
    control_socket="${probe_dir}/control"
    trap 'rm -rf -- "$probe_dir"' EXIT HUP INT TERM
    echo "正在执行非交互 SSH 握手检查（连接超时 5 秒，不运行远程命令）..."
    if ! ssh -M -S "$control_socket" -fN \
        -o BatchMode=yes \
        -o ConnectTimeout=5 \
        -o StrictHostKeyChecking=yes \
        "$target"; then
        return 1
    fi
    ssh -S "$control_socket" -O exit "$target"
)

cluster_connect_after_probe() {
    local target="$1" answer
    cluster_probe_alias "$target" || {
        echo "连通性检查失败，未启动 SSH 会话。"
        return 1
    }
    read -r -p "SSH 握手成功，是否启动交互会话? [y/N] " answer
    case "$answer" in
        y|Y|yes|YES) ssh "$target" ;;
        *) echo "已取消连接。"; return 0 ;;
    esac
}

cluster_menu() {
    local choice target
    while true; do
        clear
        echo "▶ $(t cluster_title '服务器集群控制')"
        echo "$(t cluster_hint '提示：先在 ~/.ssh/config 中为每台服务器配置 Host 别名和密钥。')"
        echo "1. $(t cluster_list '查看 SSH 配置别名')"
        echo "2. $(t cluster_connect '测试并连接 SSH 别名')"
        echo "3. $(t cluster_probe '仅测试 SSH 别名连通性')"
        echo "0. $(t common_back '返回主菜单')"
        read -r -p "请选择: " choice
        case "$choice" in
            1)
                if ! cluster_list_aliases; then
                    echo "未找到 ${HOME}/.ssh/config。"
                fi
                ;;
            2|3)
                read -r -p "SSH Host 别名: " target
                if [ "$choice" = "2" ]; then
                    cluster_connect_after_probe "$target"
                else
                    if cluster_probe_alias "$target"; then
                        echo "SSH 握手检查成功。"
                    else
                        echo "SSH 握手检查失败。"
                    fi
                fi
                ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
