#!/bin/bash
# ============================================================
# 模块: env_manage (常用环境管理)
# 来源: ssh_tool.sh 主菜单选项15 (第5749-6205行)
# 依赖: lib/common.sh (install, remove, install_nodejs, install_java, break_end, main_menu, 颜色变量)
# ============================================================
remove_managed_python_install() {
    local install_prefix="$1"
    local local_bin="$2"
    local command_name link_path resolved_target

    if [ -d "$install_prefix" ] && [ ! -f "${install_prefix}/.ssh-toolbox-managed" ]; then
        echo "保留未标记为工具箱管理的 Python 安装: ${install_prefix}" >&2
        return 0
    fi

    for command_name in python3 pip3; do
        link_path="${local_bin}/${command_name}"
        if [ -L "$link_path" ]; then
            resolved_target=$(readlink -f "$link_path" 2>/dev/null || true)
            if [[ "$resolved_target" == "${install_prefix}/"* ]]; then
                rm -f -- "$link_path" || return 1
            fi
        fi
    done

    if [ -d "$install_prefix" ]; then
        rm -rf -- "$install_prefix"
    fi
}

env_manage_menu() {
while true; do
    clear
    echo -e "${skyblue}▶ 常用环境管理${re}"
    echo "------------------------"
    echo -e "${green}1. 一键安装Python最新版${re}"
    echo -e "${green}2. 一键安装Nodejs最新版${re}"
    echo -e "${green}3. 一键安装Golang最新版${re}"
    echo -e "${green}4. 一键安装Java最新版${re}"
    echo "------------------------"
    echo -e "${red}5. 一键卸载Python${re}"
    echo -e "${red}6. 一键卸载Nodejs${re}"
    echo -e "${red}7. 一键卸载Golang${re}"
    echo -e "${red}8. 一键卸载Java${re}"
    echo "------------------------"
    echo -e "${skyblue}0. 返回主菜单${re}"
    echo "------------------------"
    read -p "$(echo -e ${red}请输入你的选择: ${re})" sub_choice

    case $sub_choice in
        1)
            clear
            OS=$(grep -o -E "Debian|Ubuntu|CentOS|Alpine|Fedora|Rocky|AlmaLinux|Amazon" /etc/os-release 2>/dev/null | head -n 1)
            if [[ -n $OS ]]; then
                echo -e "${green}检测到你的系统是${yellow}${OS}${re}"
            else
                echo -e "${red}很抱歉，暂不支持的系统！${re}"
                sleep 2; return 0
            fi
            VERSION=$(python3 -V 2>&1 | awk '{print $2}')
            PY_VERSION=$(curl -fsSL --max-time 15 https://www.python.org/downloads/ 2>/dev/null |
                grep -oE 'Download Python [0-9]+\.[0-9]+\.[0-9]+' |
                head -n 1 | awk '{print $3}')
            if [[ ! "$PY_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo -e "${red}无法从 python.org 确认最新 Python 3 版本，请检查网络后重试。${re}"
                return 1
            fi
            if [ -e /usr/local/python3 ] &&
                [ ! -f /usr/local/python3/.ssh-toolbox-managed ]; then
                echo -e "${red}/usr/local/python3 已存在且不是工具箱标记的安装；为保护现有文件，已停止安装。${re}" >&2
                return 1
            fi
            if [[ $VERSION == "3"* ]]; then
                if [ "$VERSION" = "$PY_VERSION" ]; then
                    echo -e "${green}检测到你的Python3版本已经是最新版本:${red}${PY_VERSION}${green}，无需安装或升级${re}"
                    sleep 2; return 0
                else
                    echo -e "${yellow}检测到你的Python3版本:${red}${VERSION}${yellow},最新版本:${green}${PY_VERSION}${re}"
                    read -r -p "$(echo -e ${red}是否在独立目录安装最新版Python 3（保留系统 Python）？[y/n]: ${re})" confirm
                    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                        echo -e "${yellow}已取消升级Python3${re}"; sleep 1; return 0
                    fi
                fi
            else
                echo -e "${red}检测到没有安装Python3。${re}"
                read -p "$(echo -e ${red}是否确认安装最新版Python3？[y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    echo -e "${green}开始安装最新版Python3...${re}"
                else
                    echo -e "${yellow}已取消安装Python3${re}"; return 0
                fi
            fi
            if [[ $OS == "CentOS" ]]; then
                yum groupinstall -y "development tools" &&
                    yum install wget tar openssl-devel bzip2-devel libffi-devel zlib-devel -y || return 1
            elif [[ $OS == "Fedora" ]] || [[ $OS == "Rocky" ]] || [[ $OS == "AlmaLinux" ]] || [[ $OS == "Amazon" ]]; then
                dnf groupinstall -y "development tools" &&
                    dnf install wget tar openssl-devel bzip2-devel libffi-devel zlib-devel -y || return 1
            elif [[ $OS == "Alpine" ]]; then
                apk add python3 py3-pip wget tar openssl-dev bzip2-dev libffi-dev zlib-dev || return 1
                sleep 2; break_end; return 0
            else
                apt-get update &&
                    DEBIAN_FRONTEND=noninteractive apt-get install -y wget tar build-essential libreadline-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev || return 1
            fi
            local build_dir
            build_dir=$(mktemp -d "${TMPDIR:-/tmp}/ssh-toolbox-python.XXXXXX") || return 1
            if ! curl -fsSL --max-time 60 \
                "https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tgz" \
                -o "${build_dir}/Python-${PY_VERSION}.tgz" ||
                ! tar -xzf "${build_dir}/Python-${PY_VERSION}.tgz" -C "$build_dir"; then
                rm -rf -- "$build_dir"
                echo -e "${red}无法下载或解压 Python ${PY_VERSION}。${re}" >&2
                return 1
            fi
            mkdir -p /usr/local/python3 || {
                rm -rf -- "$build_dir"
                return 1
            }
            printf 'managed by SSH Toolbox\n' > /usr/local/python3/.ssh-toolbox-managed || {
                rm -rf -- "$build_dir"
                return 1
            }
            if ! (
                cd "${build_dir}/Python-${PY_VERSION}" &&
                ./configure --prefix=/usr/local/python3 &&
                make -j "$(getconf _NPROCESSORS_ONLN)" &&
                make install
            ); then
                rm -rf -- "$build_dir"
                echo -e "${red}Python3编译或安装失败。${re}" >&2
                return 1
            fi
            rm -rf -- "$build_dir"
            mkdir -p /usr/local/bin || return 1
            local command_name command_path
            for command_name in python3 pip3; do
                command_path="/usr/local/bin/${command_name}"
                if [ -L "$command_path" ]; then
                    local current_target
                    current_target=$(readlink -f "$command_path" 2>/dev/null || true)
                    if [[ "$current_target" == /usr/local/python3/* ]]; then
                        ln -sfn "/usr/local/python3/bin/${command_name}" "$command_path" || return 1
                    else
                        echo -e "${yellow}保留现有 ${command_path}，未覆盖非工具箱管理的链接。${re}"
                    fi
                elif [ ! -e "$command_path" ]; then
                    ln -s "/usr/local/python3/bin/${command_name}" "$command_path" || return 1
                else
                    echo -e "${yellow}保留现有 ${command_path}，请使用 /usr/local/python3/bin/${command_name}。${re}"
                fi
            done
            clear; echo -e "${yellow}Python3已安装${green}成功，${re}版本为: ${green}${PY_VERSION}${re}"; sleep 2
            ;;
        2)
            clear
            if command -v node &>/dev/null; then
                current_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
                install jq
                json_data=$(curl -s https://nodejs.org/dist/index.json)
                latest_version=$(echo "$json_data" | jq -r '.[] | select(.lts != null) | .version' | head -n 1 | sed 's/^v//')
                if [ "$current_version" = "$latest_version" ]; then
                    echo -e "${yellow}当前版本${green}$current_version${yellow}已经是最新版${green}${latest_version}${yellow}，无需更新！${re}"
                    sleep 2; return 0
                else
                    echo -e "${yellow}你的nodejs版本是${re}${red}${current_version}${re}，${yellow}最新版本是${purple}${latest_version}${re}"
                    read -p "$(echo -e ${red}是否卸载旧版nodejs并安装最新版？[y/n]: ${re})" confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        remove nodejs npm || return 1
                        sleep 1
                        install_nodejs || return 1
                    else
                        return 0
                    fi
                fi
            else
                install_nodejs; break_end
            fi
            ;;
        3)
            clear
            html=$(curl -s https://go.dev/dl/)
            latest_version=$(echo "$html" | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
            if ! [[ "$latest_version" =~ ^go[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                echo -e "${red}无法从 go.dev 检测 Go 最新版本，请检查网络后重试。${re}" >&2
                return 1
            fi
            architecture=$(uname -m)
            case "$architecture" in
                x86_64|amd64) latest_version_url="https://golang.org/dl/${latest_version}.linux-amd64.tar.gz" ;;
                x86)          latest_version_url="https://golang.org/dl/${latest_version}.linux-386.tar.gz" ;;
                arm64|aarch64) latest_version_url="https://golang.org/dl/${latest_version}.linux-arm64.tar.gz" ;;
                *) echo -e "${red}暂不支持的系统架构：$architecture${re}"; sleep 2; return 0 ;;
            esac
            if command -v go &> /dev/null; then
                installed_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+')
                echo -e "${yellow}当前已安装的Go版本：${red}$installed_version${re}"
                if [ "$installed_version" = "$latest_version" ]; then
                    echo -e "${green}当前Go已经是最新版本，无需更新。${re}"; sleep 2; return 0
                else
                    echo -e "${yellow}发现新版本：$latest_version。${re}"
                    read -p "$(echo -e ${red}需要卸载当前版本 $installed_version 并安装新版本 $latest_version 吗 [y/n]: ${re})" confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        resolved_go=$(readlink -f "$(command -v go)" 2>/dev/null || true)
                        if [[ "$resolved_go" != /usr/local/go/bin/go ]]; then
                            echo -e "${red}Go并非位于工具箱使用的 /usr/local/go 安装路径；为保护现有安装，已取消覆盖。${re}" >&2
                            return 1
                        fi
                        echo "卸载旧版Go：$installed_version"
                        rm -rf -- /usr/local/go || return 1
                    else
                        echo -e "${yellow}退出更新。${re}"
                        sleep 2
                        return 0
                    fi
                fi
            else
                echo -e "${yellow}系统中未安装Go，正在为你安装最新版Go...${re}"
            fi
            if [ -e /usr/local/go ]; then
                echo -e "${red}/usr/local/go 已存在但当前 Go 命令未确认由该路径提供；为避免覆盖现有文件，已停止安装。${re}" >&2
                return 1
            fi
            install tar || return 1
            go_archive=$(mktemp "${TMPDIR:-/tmp}/ssh-toolbox-go.XXXXXX.tar.gz") || return 1
            if ! curl -fsSL --max-time 60 "$latest_version_url" -o "$go_archive" ||
                ! tar -C /usr/local -xzf "$go_archive"; then
                rm -f -- "$go_archive"
                echo -e "${red}Go 下载或解压失败。${re}" >&2
                return 1
            fi
            rm -f -- "$go_archive"
            GO_PATH="/usr/local/go/bin"
            if [[ ":$PATH:" != *":${GO_PATH}:"* ]]; then
                go_profile=/etc/profile.d/ssh-toolbox-go.sh
                if [ -e "$go_profile" ] &&
                    ! grep -q '^# SSH_TOOLBOX_MANAGED_GO_PATH$' "$go_profile"; then
                    echo -e "${yellow}保留现有 ${go_profile}，请手动将 ${GO_PATH} 加入 PATH。${re}"
                else
                    printf '# SSH_TOOLBOX_MANAGED_GO_PATH\nexport PATH=%s:$PATH\n' "$GO_PATH" > "$go_profile" || return 1
                    chmod 644 "$go_profile" || return 1
                fi
            fi
            export PATH="${GO_PATH}:${PATH}"
            if command -v go &> /dev/null; then
                echo -e "${green}GO安装完成，当前Go版本：${red}$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+' | cut -c 3-)${re}"
                echo -e "${red}退出脚本后请手动执行以下命令使全局环境变量生效：${yellow}source /etc/profile${re}"
            else
                echo -e "${red}Go安装完成，但全局环境变量未生效，请退出脚本后手动执行以下命令使全局环境变量生效：${yellow}source /etc/profile${re}"
            fi
            sleep 1; break_end
            ;;
        4)
            clear
            if command -v java &>/dev/null; then
                installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
                latest_version="17.0.10"
                echo -e "${green}当前Java版本是${yellow}${installed_version},最新版本是${green}${latest_version}${re}"
                if [ "$installed_version" == "$latest_version" ]; then
                    echo -e "${green}当前已安装Java最新版：${yellow}${latest_version},无需更新${re}"; sleep 2; return 0
                else
                    read -p "$(echo -e ${red}是否卸载旧版java并安装最新版？[y/n]: ${re})" confirm
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        remove java; sleep 2; install_java
                    else
                        return 0
                    fi
                fi
            else
                install_java
            fi
            ;;
        5)
            clear
            if command -v python3 &>/dev/null; then
                current_version=$(python3 --version 2>&1 | awk '{print $2}')
                echo -e "${yellow}当前已安装python${red}${current_version}${re}"
                read -p "$(echo -e ${red}确定卸载python？[y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    remove_managed_python_install /usr/local/python3 /usr/local/bin
                    echo -e "${yellow}仅移除了工具箱独立安装的 Python；系统包管理器管理的 Python 已保留。${re}"
                    echo -e "${green}python已卸载${re}"; break_end
                else
                    return 0
                fi
            else
                echo -e "${yellow}系统中未安装python，无需卸载${re}"; sleep 2; return 0
            fi
            ;;
        6)
            clear
            if command -v node &>/dev/null; then
                current_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
                echo -e "${yellow}当前已安装nodejs${red}$current_version${re}"
                read -p "$(echo -e ${red}确定卸载nodejs？[y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    remove nodejs npm || return 1
                    echo -e "${green}nodejs已卸载${re}"; break_end
                else
                    return 0
                fi
            else
                echo -e "${yellow}系统中未安装nodejs，无需卸载${re}"; sleep 2; return 0
            fi
            ;;
        7)
            clear
            if command -v go &> /dev/null; then
                installed_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+' | cut -c 3-)
                echo -e "${yellow}当前已安装Go：${red}$installed_version${re}"
                read -p "$(echo -e ${red}确定卸载Go？[y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    resolved_go=$(readlink -f "$(command -v go)" 2>/dev/null || true)
                    if [[ "$resolved_go" == /usr/local/go/bin/go ]]; then
                        rm -rf -- /usr/local/go || return 1
                    else
                        echo -e "${yellow}Go 不在工具箱管理路径 /usr/local/go；未删除现有文件。${re}"
                    fi
                    go_profile=/etc/profile.d/ssh-toolbox-go.sh
                    if [ -f "$go_profile" ] && grep -q '^# SSH_TOOLBOX_MANAGED_GO_PATH$' "$go_profile"; then
                        rm -f -- "$go_profile" || return 1
                    fi
                    echo -e "${green}Go已卸载${re}"; sleep 1; break_end
                else
                    return 0
                fi
            else
                echo -e "${yellow}系统中未安装Go，无需卸载${re}"; sleep 2; return 0
            fi
            ;;
        8)
            clear
            if command -v java &> /dev/null; then
                installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
                echo -e "${yellow}你的Java版本：${red}${installed_version}${re}"
                read -p "$(echo -e ${red}确定卸载Java？[y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    if command -v apt &>/dev/null; then
                        apt remove -y openjdk-17-jdk || return 1
                    elif command -v yum &>/dev/null; then
                        yum remove -y java-17-openjdk || return 1
                    elif command -v dnf &>/dev/null; then
                        dnf remove -y java-17-openjdk || return 1
                    elif command -v apk &>/dev/null; then
                        apk del openjdk17 || return 1
                    else
                        echo -e "${red}未找到受支持的软件包管理器，未卸载 Java。${re}" >&2
                        return 1
                    fi
                    echo -e "${green}Java卸载成功！${re}"
                    read -p "$(echo -e ${red}重启服务器配置才可生效，需要立即重启吗 [y/n]: ${re})" confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        sleep 1; reboot
                    else
                        return 0
                    fi
                else
                    return 0
                fi
            else
                echo -e "${yellow}系统中未安装Java，无需卸载${re}"; sleep 2
            fi
            ;;
        0) return 0 ;;
        *) echo -e "${yellow}无效的输入!${re}" ;;
    esac
done
}
