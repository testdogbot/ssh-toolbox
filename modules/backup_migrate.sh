#!/bin/bash
# ============================================================
# 模块: backup_migrate (网站备份与恢复)
# ============================================================
backup_migrate_menu() {
    local choice source_path archive target_path entry listing bad_entry
    local backup_dir="${HOME}/ssh-toolbox-backups"
    while true; do
        clear
        echo "▶ 网站备份与迁移"
        echo "1. 备份目录为压缩包"
        echo "2. 将本工具生成的压缩包恢复到目录"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1)
                read -r -p "要备份的目录: " source_path
                if [ ! -d "$source_path" ]; then
                    echo "目录不存在。"
                    continue
                fi
                mkdir -p "$backup_dir" || return 1
                archive="${backup_dir}/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
                tar -czf "$archive" -C "$(dirname "$source_path")" "$(basename "$source_path")" &&
                    echo "备份完成: $archive"
                ;;
            2)
                read -r -p "备份文件名（位于 ${backup_dir}）: " archive
                if [[ "$archive" != "$(basename "$archive")" || ! -f "${backup_dir}/${archive}" ]]; then
                    echo "只能选择备份目录中存在的文件名。"
                    continue
                fi
                read -r -p "恢复目标目录（必须是已存在目录）: " target_path
                if [ ! -d "$target_path" ]; then
                    echo "目标目录不存在。"
                    continue
                fi
                listing=$(tar -tzf "${backup_dir}/${archive}") || {
                    echo "无法读取压缩包。"
                    continue
                }
                bad_entry=0
                while IFS= read -r entry; do
                    if [[ "$entry" == /* || "$entry" == .. || "$entry" == ../* || "$entry" == */../* || "$entry" == */.. ]]; then
                        bad_entry=1
                        break
                    fi
                done <<< "$listing"
                if [ "$bad_entry" -eq 1 ]; then
                    echo "压缩包包含不安全路径，拒绝恢复。"
                    continue
                fi
                confirm_action "解压到 ${target_path}（同名文件可能被覆盖）?" &&
                    tar --no-same-owner --no-same-permissions -xzf "${backup_dir}/${archive}" -C "$target_path"
                ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
