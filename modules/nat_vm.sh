#!/bin/bash
# ============================================================
# 模块: nat_vm (NAT小鸡管理)
# 来源: ssh_tool.sh 主菜单选项16 (第6207-6956行)
# 依赖: lib/common.sh (install, break_end, main_menu, 颜色变量)
# 功能: KVM/LXC/Docker/Incus 虚拟化小鸡开设与管理
# ============================================================
nat_vm_menu() {
while true; do
    clear
    echo -e "${purple}▶ 管理NAT小鸡${re}"
    echo "------------------------"
    echo -e "${yellow}开设kvm小鸡分两步，请依次执行。${re}"
    echo -e "${yellow}如果第一步失败，请选择其他方式开设小鸡。${re}"
    echo -e "${yellow}建议选择4或9，大部分vps都兼容！${re}"
    echo "------------------------"
    echo -e "${skyblue} 1. 开设KVM小鸡(第1步)${re}"
    echo -e "${skyblue} 2. 开设KVM小鸡(第2步)${re}"
    echo -e "${red} 3. 删除所有KVM小鸡${re}"
    echo "------------------------"
    echo -e "${green} 4. 开设LXC小鸡(官方版)${re}"
    echo -e "${green} 5. 开设LXC小鸡(魔改版)${re}"
    echo -e "${skyblue} 6. 管理LXC小鸡 ▶${re}"
    echo "------------------------"
    echo -e "${green} 7. 开设Docker小鸡${re}"
    echo -e "${red} 8. 删除所有Docker容器${re}"
    echo "------------------------"
    echo -e "${green} 9. 开设incus小鸡(官方版)${re}"
    echo -e "${skyblue}10. 管理incus小鸡 ▶${re}"
    echo "------------------------"
    echo -e "${skyblue} 0. 返回主菜单${re}"
    echo "------------------------"
    while :; do
        echo
        read -p "$(echo -e ${red}请输入你的选择: ${re})" sub_choice
        if ! [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
            echo -e "${red}输入错误, 请输入0~10的数字!${re}"
            continue
        fi
        if [ $sub_choice -ge 0 -a $sub_choice -le 12 ]; then
            break
        else
            echo -e "${red}输入错误, 请输入0~10的数字!${re}"
        fi
    done

    case $sub_choice in
        1)
            clear
            echo -e "${yellow}开始进行环境检测...${re}"
            install wget
            output=$(bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/pve/main/scripts/check_kernal.sh))
            echo "$output"
            if echo "$output" | grep -q "CPU不支持硬件虚拟化"; then
                echo ""
                echo -e "${red}你的服务器不支持开设KVM小鸡，建议选择4或9开设其他类型，正在退出...${re}"
                rm -rf /root/check_kernal.sh
                sleep 2; break_end
            elif echo "$output" | grep -q "本机符合要求"; then
                echo -e "${green}本机符合开设kvm小鸡的要求${re}"
                read -p "$(echo -e ${purple}确定要开设kvm小鸡吗？ [y/n]: ${re})" confirm
                sleep 1
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    echo -e "${yellow}开设虚拟内存(Swap),请先输入2移除原来的配置，会自动重新执行一次，再输入1添加虚拟内存${re}"
                    curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                    sleep 1
                    curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                    echo -e "${yellow}开始进行PVE主体安装${re}"
                    curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
                    sleep 1
                    echo -e "${yellow}请等待20秒后重启后运行第2步${re}"
                    read -p "$(echo -e ${skyblue}需要立即重启吗？ [y/n]: ${re})" confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        sleep 1; reboot
                    else
                        break_end
                    fi
                else
                    echo -e "${yellow}已取消操作...${re}"; sleep 2; return 0
                fi
            elif echo "$output" | grep -q "宿主机的环境无apt包管理器命令"; then
                echo ""
                echo -e "${red}你的vps系统暂不支持，请更换Debian12或Ubuntu22.04后重试${re}"
                sleep 3; return 0
            else
                echo -e "${red}暂不能判定你的服务器状态，无法开设kvm小鸡，可以考虑使用LXC模式开小鸡，正在退出...${re}"
                rm -rf /root/check_kernal.sh; sleep 3; return 0
            fi
            ;;
        2)
            clear
            read -p "$(echo -e ${skyblue}确认你已执行完第1步，是否继续 [y/n]: ${re})" confirm
            if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                sleep 1
                curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
                sleep 1
                echo -e "${yellow}开始配置环境...${re}"
                bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/build_backend.sh)
                sleep 1
                echo -e "${yellow}开始自动配置宿主机的网关...${re}"
                bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/build_nat_network.sh)
                sleep 1
                echo -e "${yellow}KVM虚拟化开设出的虚拟机，默认生成的用户名不是root，请确保你已在root下运行及修改root密码${re}"
                while true; do
                    read -p "$(echo -e "${skyblue}你需要手动开设kvm小鸡还是批量开设kvm小鸡？(1：手动开设  2：自动批量开设) ${re}")" choose
                    if [ "$choose" == "1" ]; then
                        sleep 1
                        curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/buildvm.sh -o buildvm.sh && chmod +x buildvm.sh
                        sleep 2
                        echo -e "${purple}手动开设请执行以下命令，参数对照如下可自行修改${re}"
                        echo ""
                        echo -e "${purple}./buildvm.sh VMID 用户名 密码 CPU核数 内存 硬盘 SSH端口 80端口 443端口 外网端口起 外网端口止 系统 存储盘 独立IPV6地址(留空默认N)${re}"
                        echo -e "${purple}./buildvm.sh 102 test1 oneclick123 1 512 10 40001 40002 40003 50000 50025 debian11 local N${re}"
                        sleep 3; break_end; break
                    elif [ "$choose" == "2" ]; then
                        sleep 1
                        echo -e "${red}注意: KVM开设出的NAT小鸡，默认生成的用户名不是root，默认的root密码部分类型是${green}password${red},需要sudo -i手动切换为root${re}"
                        sleep 2
                        curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/create_vm.sh -o create_vm.sh && chmod +x create_vm.sh && bash create_vm.sh
                        sleep 2; break_end; break
                    else
                        echo -e "${red}输入错误，请输入1或2${re}"
                    fi
                done
            else
                break_end
            fi
            ;;
        3)
            clear
            if ! command -v qm >/dev/null 2>&1; then
                echo -e "${red}未检测到 Proxmox qm 命令，无法删除 KVM 虚拟机。${re}"
                break_end
                continue
            fi
            if ! vm_list=$(qm list); then
                echo -e "${red}读取 Proxmox 虚拟机列表失败，未执行删除。${re}" >&2
                break_end
                continue
            fi
            mapfile -t vmids < <(printf '%s\n' "$vm_list" | awk 'NR > 1 && $1 ~ /^[0-9]+$/ {print $1}')
            if [ "${#vmids[@]}" -eq 0 ]; then
                echo -e "${yellow}没有检测到可删除的 KVM 虚拟机。${re}"
                break_end
                continue
            fi
            printf '将删除以下虚拟机：%s\n' "${vmids[*]}"
            read -r -p "此操作不可撤销，请输入 DELETE 确认: " confirm
            if [ "$confirm" = "DELETE" ]; then
                for vmid in "${vmids[@]}"; do
                    if ! vm_status=$(qm status "$vmid"); then
                        echo -e "${red}无法读取虚拟机 ${vmid} 状态，已跳过。${re}" >&2
                        continue
                    fi
                    if [[ "$vm_status" == *"status: running"* ]] && ! qm stop "$vmid"; then
                        echo -e "${red}停止虚拟机 ${vmid} 失败，已跳过删除。${re}" >&2
                        continue
                    fi
                    if qm destroy "$vmid"; then
                        echo -e "${green}已删除虚拟机 ${vmid}${re}"
                    else
                        echo -e "${red}删除虚拟机 ${vmid} 失败，请检查 Proxmox 日志。${re}" >&2
                    fi
                done
                echo -e "${yellow}未修改宿主机防火墙、网络配置或当前目录中的文件。${re}"
            else
                echo -e "${yellow}已取消删除。${re}"
            fi
            break_end
            ;;
        4)
            clear
            echo -e "${yellow}开始进行环境检测...${re}"
            install wget
            output=$(bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/pre_check.sh))
            echo "$output"
            if echo "$output" | grep -q "本机符合作为LXC母鸡的要求"; then
                echo ""
                echo -e "${green}你的vps已通过检测，可以开设LXC小鸡${re}"
                read -p "$(echo -e ${purple}确定要开设LXC小鸡吗？ [y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    echo -e "${yellow}开始进行安装LXD主体...${re}"
                    sleep 1
                    curl -L https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/lxdinstall.sh -o lxdinstall.sh && chmod +x lxdinstall.sh && bash lxdinstall.sh
                    sleep 3
                    if command lxc -h &> /dev/null; then
                        echo -e "${green}LXD主体已安装完成${re}"; sleep 1
                    else
                        echo -e "${yellow}lxc没有软连接上，正在为你修复...${re}"
                        apt update -y
                        ! lxc -h >/dev/null 2>&1 && echo 'alias lxc="/snap/bin/lxc"' >> /root/.bashrc && source /root/.bashrc
                        export PATH=$PATH:/snap/bin
                        if command lxc -h &> /dev/null; then
                            sleep 1
                        else
                            echo -e "${yellow}lxc没有软连接上，请重启系统后重新运行${re}"; sleep 2; return 0
                        fi
                    fi
                    echo -e "${yellow}开始批量开设LXC小鸡...${re}"
                    bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/build_lxd.sh)
                    sleep 2; break_end
                else
                    return 0
                fi
            else
                echo -e "${red}你的服务器不符合要求，无法开设LXC小鸡${re}"
                sleep 3; return 0
            fi
            ;;
        5)
            clear
            echo -e "${yellow}开始进行LXC魔改版安装...${re}"
            install wget
            bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/lxdinstall.sh)
            sleep 2
            echo -e "${yellow}开始批量开设LXC小鸡(魔改版)...${re}"
            bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/lxd/main/scripts/build.sh)
            sleep 2; break_end
            ;;
        6)
            clear
            echo -e "${purple}▶ 管理LXC小鸡${re}"
            echo "------------------------"
            echo -e "${green} 1. 查看所有LXC容器${re}"
            echo -e "${green} 2. 启动LXC容器${re}"
            echo -e "${green} 3. 停止LXC容器${re}"
            echo -e "${green} 4. 删除LXC容器${re}"
            echo -e "${green} 5. 进入LXC容器${re}"
            echo -e "${green} 6. 查看LXC容器资源${re}"
            echo -e "${skyblue} 0. 返回上一级${re}"
            echo "------------------------"
            read -p "$(echo -e ${red}请输入你的选择: ${re})" lxc_choice
            case $lxc_choice in
                1) lxc list ;;
                2) read -p "请输入容器名: " name; lxc start "$name" ;;
                3) read -p "请输入容器名: " name; lxc stop "$name" ;;
                4) read -p "请输入容器名: " name; lxc delete "$name" --force ;;
                5) read -p "请输入容器名: " name; lxc exec "$name" -- bash ;;
                6) lxc list --format csv -c n,s,m,c,t ;;
                0) ;;
            esac
            break_end
            ;;
        7)
            clear
            echo -e "${yellow}开始开设Docker小鸡...${re}"
            install_docker || {
                echo -e "${red}Docker 安装或检查失败，已停止操作。${re}" >&2
                break_end
                continue
            }
            read -r -p "$(echo -e "${purple}请输入要开设的Docker小鸡数量 (1-20): ${re}")" count
            if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ] || [ "$count" -gt 20 ]; then
                echo -e "${red}数量必须是 1 到 20 之间的整数。${re}"
                break_end
                continue
            fi
            if ! command -v od >/dev/null 2>&1 || ! command -v tr >/dev/null 2>&1; then
                echo -e "${red}缺少生成随机密码所需的 od 或 tr 命令。${re}" >&2
                break_end
                continue
            fi
            for i in $(seq 1 "$count"); do
                name="vm-$i"
                if docker container inspect "$name" >/dev/null 2>&1; then
                    echo -e "${yellow}容器 ${name} 已存在，跳过以保留现有容器。${re}"
                    continue
                fi
                password=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n') || {
                    echo -e "${red}无法生成随机密码，已停止创建。${re}" >&2
                    break
                }
                if [ "${#password}" -ne 32 ]; then
                    echo -e "${red}生成的随机密码长度无效，已停止创建。${re}" >&2
                    break
                fi
                if ! docker run -d --name="$name" --cpus=1 --memory=512m \
                    -p "$(shuf -i 20000-60000 -n 1):22" \
                    -v "/root/${name}:/root" \
                    --restart unless-stopped \
                    debian:latest /bin/bash -c "apt update && apt install -y openssh-server && \
                    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
                    service ssh start && sleep infinity"; then
                    echo -e "${red}创建容器 ${name} 失败。${re}" >&2
                    continue
                fi
                if ! printf 'root:%s\n' "$password" | docker exec -i "$name" chpasswd; then
                    docker rm -f "$name" >/dev/null 2>&1 || true
                    echo -e "${red}设置 ${name} 的随机密码失败，已清理容器。${re}" >&2
                    continue
                fi
                umask 077
                printf '容器: %s\n用户名: root\n密码: %s\nSSH映射: %s\n\n' \
                    "$name" "$password" "$(docker port "$name" 22/tcp 2>/dev/null || echo '查询失败')" \
                    >> /root/ssh-toolbox-vm-credentials.txt
                chmod 600 /root/ssh-toolbox-vm-credentials.txt
                echo -e "${green}容器 ${name} 已创建；凭据已追加至 /root/ssh-toolbox-vm-credentials.txt（权限 600）。${re}"
            done
            docker ps
            break_end
            ;;
        8)
            clear
            if ! command -v docker >/dev/null 2>&1; then
                echo -e "${red}未检测到 Docker，无法删除容器。${re}"
            else
                if ! container_list=$(docker ps -aq); then
                    echo -e "${red}读取 Docker 容器列表失败，未执行删除。${re}" >&2
                else
                    mapfile -t container_ids <<<"$container_list"
                    if [ -z "$container_list" ]; then
                        echo -e "${yellow}没有检测到 Docker 容器。${re}"
                    else
                        echo -e "${red}将删除全部 ${#container_ids[@]} 个 Docker 容器，包括非工具箱创建的容器。${re}"
                        read -r -p "此操作不可撤销，请输入 DELETE 确认: " confirm
                        if [ "$confirm" = "DELETE" ]; then
                            if docker rm -f "${container_ids[@]}"; then
                                echo -e "${green}所有 Docker 容器已删除。${re}"
                            else
                                echo -e "${red}部分 Docker 容器删除失败，请检查 Docker 状态。${re}" >&2
                            fi
                        else
                            echo -e "${yellow}已取消删除。${re}"
                        fi
                    fi
                fi
            fi
            break_end
            ;;
        9)
            clear
            echo -e "${yellow}开始进行环境检测...${re}"
            install wget
            output=$(bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/pre_check.sh))
            echo "$output"
            if echo "$output" | grep -q "本机符合作为incus母鸡的要求"; then
                echo ""
                echo -e "${green}你的vps已通过检测，可以开设incus小鸡${re}"
                read -p "$(echo -e ${purple}确定要开设incus小鸡吗？ [y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    echo -e "${yellow}开始进行安装incus主体...${re}"
                    sleep 1
                    bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/incusinstall.sh)
                    sleep 3
                    echo -e "${yellow}开始批量开设incus小鸡...${re}"
                    bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/build_incus.sh)
                    sleep 2; break_end
                else
                    return 0
                fi
            else
                echo -e "${red}你的服务器不符合要求，无法开设incus小鸡${re}"
                sleep 3; return 0
            fi
            ;;
        10)
            clear
            echo -e "${purple}▶ 管理incus小鸡${re}"
            echo "------------------------"
            echo -e "${green} 1. 查看所有incus容器${re}"
            echo -e "${green} 2. 启动incus容器${re}"
            echo -e "${green} 3. 停止incus容器${re}"
            echo -e "${green} 4. 删除incus容器${re}"
            echo -e "${green} 5. 进入incus容器${re}"
            echo -e "${skyblue} 0. 返回上一级${re}"
            echo "------------------------"
            read -p "$(echo -e ${red}请输入你的选择: ${re})" incus_choice
            case $incus_choice in
                1) incus list ;;
                2) read -p "请输入容器名: " name; incus start "$name" ;;
                3) read -p "请输入容器名: " name; incus stop "$name" ;;
                4) read -p "请输入容器名: " name; incus delete "$name" --force ;;
                5) read -p "请输入容器名: " name; incus exec "$name" -- bash ;;
                0) ;;
            esac
            break_end
            ;;
        0) return 0 ;;
        *) echo -e "${red}无效的输入!${re}" ;;
    esac
done
}
