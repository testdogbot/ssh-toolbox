#!/bin/bash
# ============================================================
# 模块: kpanel (KPanel)
# ============================================================
kpanel_menu() {
    local choice container_list target input container_id container_name action
    local -a containers
    while true; do
        clear
        echo "▶ KPanel Web 面板"
        echo "1. 查看 KPanel 容器"
        echo "2. 启动 KPanel 容器"
        echo "3. 停止 KPanel 容器"
        echo "4. 重启 KPanel 容器"
        echo "5. 查看最近容器日志"
        echo "6. 查看容器资源使用"
        echo "7. 查看官方部署说明"
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
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
