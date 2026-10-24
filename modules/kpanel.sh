#!/bin/bash
# ============================================================
# 模块: kpanel (KPanel)
# ============================================================
kpanel_deploy_preflight() (
    local version=v1.27.2 release_base meta_digest image_digest arch agent_digest temp_dir archive agent_url public_url network_subnet answer installer preflight checksum_file agent_file member
    version=v1.27.2
    release_base="https://github.com/kejilion/KPanel/releases/download/${version}"
    meta_digest=8b5fbac62fdc80023b23dea5c85c2e8f1b663047b429d03ac107543f41b3d43d
    image_digest=5369dc9a2b8151314181d306e8d490939e63607d017b07c3985a0f4afb65aa10
    case "$(uname -m)" in
        x86_64|amd64) arch=amd64; agent_digest=2447f669ca85c1d84ed228027db1f17793fb9b98b9ad0922bf602e85e4ec8543 ;;
        aarch64|arm64) arch=arm64; agent_digest=2753692383ab3fe19b2d408171c909a04cafaa8bc5ce83325ce78ae2c8e11737 ;;
        *) echo "当前架构不受 KPanel ${version} 官方发布支持。" >&2; return 1 ;;
    esac
    read -r -p "面板公网 HTTPS 根地址（例如 https://panel.example.com）: " public_url
    [[ "$public_url" =~ ^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?$ ]] || { echo "必须输入 HTTPS origin，不能包含路径。" >&2; return 1; }
    read -r -p "Docker 私网 RFC1918 /28（留空使用 172.29.255.240/28）: " network_subnet
    network_subnet=${network_subnet:-172.29.255.240/28}
    [[ "$network_subnet" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/28$ ]] || { echo "私网必须是 IPv4 /28 CIDR。" >&2; return 1; }
    temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/ssh-toolbox-kpanel.XXXXXX") || return 1
    trap 'rm -rf -- "$temp_dir"' EXIT
    archive="${temp_dir}/kpanel-meta.tar.gz"
    agent_file="${temp_dir}/kejilion-agent-linux-${arch}"
    checksum_file="${temp_dir}/SHA256SUMS"
    if ! curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --max-filesize 5000000 --max-time 120 -o "$archive" "${release_base}/kejilion-panel-meta-1.27.2.tar.gz" ||
        [ "$(sha256sum "$archive" | awk '{print $1}')" != "$meta_digest" ]; then
        echo "KPanel 固定版本元数据下载或 SHA-256 校验失败。" >&2
        return 1
    fi
    if ! curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --max-filesize 20000000 --max-time 120 -o "$agent_file" "${release_base}/kejilion-agent-linux-${arch}" ||
        [ "$(sha256sum "$agent_file" | awk '{print $1}')" != "$agent_digest" ]; then
        echo "KPanel Agent 下载或 SHA-256 校验失败。" >&2
        return 1
    fi
    if ! curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --max-time 30 -o "$checksum_file" "${release_base}/SHA256SUMS" ||
        ! grep -Eq "^${agent_digest}[[:space:]]+\*?kejilion-agent-linux-${arch}$" "$checksum_file"; then
        echo "官方 SHA256SUMS 不匹配，拒绝部署。" >&2
        return 1
    fi
    while IFS= read -r member; do
        case "$member" in /*|../*|*/../*|*/..) echo "元数据包包含不安全路径。" >&2; return 1 ;; esac
    done < <(tar -tzf "$archive")
    mkdir "${temp_dir}/meta" || return 1
    tar --no-same-owner --no-same-permissions -xzf "$archive" -C "${temp_dir}/meta" || return 1
    installer=$(find "${temp_dir}/meta" -type f -path '*/deploy/install.sh' -print -quit)
    preflight=$(find "${temp_dir}/meta" -type f -path '*/deploy/preflight.sh' -print -quit)
    [ -n "$installer" ] && [ -n "$preflight" ] || { echo "固定版本元数据缺少官方安装器或预检脚本。" >&2; return 1; }
    echo "已取得官方 KPanel ${version} 元数据、${arch} Agent 和固定镜像 digest，并校验 SHA-256。"
    echo "运行官方只读预检：${preflight} --public-url ${public_url} --network-subnet ${network_subnet}"
    if ! sh "$preflight" --public-url "$public_url" --network-subnet "$network_subnet"; then
        echo "官方预检未通过；没有调用安装器。"
        return 1
    fi
    echo "部署会新增 KPanel 专用文件、服务、容器与网络；不会修改 kejilion.sh、/home/web、Nginx 配置或防火墙。"
    echo "将先运行官方安装器 --dry-run，再在明确确认后进行实际安装。"
    read -r -p "确认继续请输入 INSTALL: " answer
    [ "$answer" = INSTALL ] || { echo "已取消；未安装 KPanel。"; return 1; }
    if ! sh "$installer" --agent-binary "$agent_file" --agent-sha256 "$agent_digest" \
        --image "docker.io/kjlion/kejilion-panel@sha256:${image_digest}" \
        --public-url "$public_url" --network-subnet "$network_subnet" --dry-run; then
        echo "官方安装器 dry-run 失败；没有执行实际安装。" >&2
        return 1
    fi
    read -r -p "Dry-run 通过。实际安装会写入系统服务并启动容器；再次输入 INSTALL 执行: " answer
    [ "$answer" = INSTALL ] || { echo "已取消；仅完成 dry-run。"; return 1; }
    sh "$installer" --agent-binary "$agent_file" --agent-sha256 "$agent_digest" \
        --image "docker.io/kjlion/kejilion-panel@sha256:${image_digest}" \
        --public-url "$public_url" --network-subnet "$network_subnet"
)
kpanel_menu() {
    local choice container_list target input container_id container_name action
    local -a containers
    while true; do
        clear
        echo "▶ $(t kpanel_title 'KPanel Web 面板')"
        echo "1. $(t kpanel_list '查看 KPanel 容器')"
        echo "2. $(t kpanel_start '启动 KPanel 容器')"
        echo "3. $(t kpanel_stop '停止 KPanel 容器')"
        echo "4. $(t kpanel_restart '重启 KPanel 容器')"
        echo "5. $(t kpanel_logs '查看最近容器日志')"
        echo "6. $(t kpanel_stats '查看容器资源使用')"
        echo "7. $(t kpanel_docs '查看官方部署说明')"
        echo "8. $(t kpanel_preflight '校验固定版发布资产并部署（预检和两次确认）')"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1)
                if ! command -v docker >/dev/null 2>&1; then
                    echo "未安装 Docker。"
                elif ! docker ps -a --filter name=kpanel \
                    --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'; then
                    echo "查询 KPanel 容器失败。" >&2
                fi
                ;;
            2|3|4|5|6)
                if ! command -v docker >/dev/null 2>&1; then
                    echo "未安装 Docker。"
                    break_end
                    continue
                fi
                if ! container_list=$(docker ps -aq --filter name=kpanel); then
                    echo "读取 KPanel 容器列表失败。" >&2
                    break_end
                    continue
                fi
                containers=()
                while IFS= read -r container_id; do
                    [ -n "$container_id" ] && containers+=("$container_id")
                done <<< "$container_list"
                if [ "${#containers[@]}" -eq 0 ]; then
                    echo "未发现 KPanel 容器。"
                    break_end
                    continue
                fi
                docker ps -a --filter name=kpanel \
                    --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}'
                if [ "${#containers[@]}" -eq 1 ]; then
                    target="${containers[0]}"
                else
                    read -r -p "输入要管理的容器 ID 或名称: " input
                    target=""
                    for container_id in "${containers[@]}"; do
                        container_name=$(docker inspect --format '{{.Name}}' "$container_id") || continue
                        container_name=${container_name#/}
                        if [ "$input" = "$container_id" ] || [ "$input" = "$container_name" ]; then
                            target="$container_id"
                            break
                        fi
                    done
                    if [ -z "$target" ]; then
                        echo "未选择有效的 KPanel 容器。"
                        break_end
                        continue
                    fi
                fi
                case "$choice" in
                    2) action=start ;;
                    3) action=stop ;;
                    4) action=restart ;;
                    5) action=logs ;;
                    6) action=stats ;;
                esac
                if [[ "$action" == start || "$action" == stop || "$action" == restart ]]; then
                    if ! confirm_action "${action} KPanel 容器 ${target}?"; then
                        echo "已取消。"
                        break_end
                        continue
                    fi
                    if docker "$action" "$target"; then
                        echo "已${action} KPanel 容器 ${target}。"
                    else
                        echo "操作 KPanel 容器 ${target} 失败。" >&2
                    fi
                elif [ "$action" = logs ]; then
                    docker logs --tail 100 "$target" ||
                        echo "读取 KPanel 容器日志失败。" >&2
                elif ! docker stats --no-stream "$target"; then
                    echo "读取 KPanel 容器资源使用失败。" >&2
                fi
                ;;
            7)
                echo "KPanel 官方说明: https://github.com/kejilion/KPanel"
                echo "部署方式和要求请以官方文档为准；本工具不会自动覆盖现有服务。"
                ;;
            8) kpanel_deploy_preflight ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
