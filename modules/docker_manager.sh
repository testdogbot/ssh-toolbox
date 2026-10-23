#!/bin/bash
# ============================================================
# 模块: docker_manager (Docker 管理)
# ============================================================
docker_require() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "未安装 Docker。"
        return 1
    fi
    if ! docker info >/dev/null 2>&1; then
        echo "无法连接 Docker daemon，请检查服务状态及权限。"
        return 1
    fi
}

docker_ps() {
    docker_require || return
    docker ps -a
}

docker_image() {
    docker_require || return
    docker images
}

docker_menu() {
    local choice target action
    while true; do
        clear
        echo "▶ Docker 管理"
        echo "1. 容器列表  2. 启动/停止/重启容器  3. 查看容器日志"
        echo "4. 镜像列表  5. 拉取镜像  6. 删除镜像"
        echo "7. 网络列表  8. 卷列表  9. 清理未使用的镜像/网络"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1) docker_ps ;;
            2)
                docker_require || continue
                read -r -p "容器 ID 或名称: " target
                [ -n "$target" ] || continue
                read -r -p "操作 (start/stop/restart): " action
                case "$action" in start|stop|restart) docker "$action" "$target" ;; *) echo "无效操作。" ;; esac
                ;;
            3)
                docker_require || continue
                read -r -p "容器 ID 或名称: " target
                [ -n "$target" ] && docker logs --tail 100 "$target"
                ;;
            4) docker_image ;;
            5)
                docker_require || continue
                read -r -p "镜像名称（含标签）: " target
                [ -n "$target" ] && docker pull "$target"
                ;;
            6)
                docker_require || continue
                read -r -p "要删除的镜像 ID: " target
                [ -n "$target" ] && confirm_action "删除镜像 ${target}?" && docker image rm "$target"
                ;;
            7) docker_require && docker network ls ;;
            8) docker_require && docker volume ls ;;
            9)
                docker_require || continue
                confirm_action "只清理未使用的镜像和网络（不删除卷）?" &&
                    docker image prune -f && docker network prune -f
                ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
