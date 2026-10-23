#!/bin/bash
#=========================================================================
# lib/common.sh - 公共函数库
# 整合自 kejilion/sh (Apache 2.0) 和 eooce/ssh_tool
# 提供颜色定义、包管理、IP获取、端口检查、快捷键设置等通用函数
#=========================================================================

# ---- 颜色定义 (兼容两个项目) ----
gl_hui='\e[37m'
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_bai='\033[0m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'

# ssh_tool 风格别名
re='\e[0m'
red='\e[1;91m'
white='\e[1;97m'
green='\e[1;32m'
yellow='\e[1;33m'
purple='\e[1;35m'
skyblue='\e[1;96m'

# ---- 路径变量 ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
MODULES_DIR="${SCRIPT_DIR}/modules"
LIB_DIR="${SCRIPT_DIR}/lib"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

# ---- GitHub 代理 ----
get_gh_proxy() {
    local country
    country=$(curl -s --max-time 3 ipinfo.io/country 2>/dev/null)
    if [ "$country" = "CN" ]; then
        echo "https://gh.kejilion.pro/"
    else
        echo "https://"
    fi
}

# ---- IP 地址获取 ----
ip_address() {
    get_public_ip() {
        curl -s --max-time 3 https://ipinfo.io/ip 2>/dev/null && echo
    }

    get_local_ip() {
        ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || \
        hostname -I 2>/dev/null | awk '{print $1}' || \
        ifconfig 2>/dev/null | grep -E 'inet [0-9]' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1
    }

    local public_ip isp_info
    public_ip=$(get_public_ip)
    isp_info=$(curl -s --max-time 3 http://ipinfo.io/org 2>/dev/null)

    if echo "$isp_info" | grep -Eiq 'CHINANET|mobile|unicom|telecom'; then
        ipv4_address=$(get_local_ip)
    else
        ipv4_address="$public_ip"
    fi

    ipv6_address=$(curl -s --max-time 2 https://v6.ipinfo.io/ip 2>/dev/null && echo)
}

# ---- 软件包安装 (取 kejilion 更完善实现，支持 8 种包管理器) ----
install() {
    if [ $# -eq 0 ]; then
        echo -e "${gl_hong}未提供软件包参数!${gl_bai}"
        return 1
    fi

    local package
    for package in "$@"; do
        if ! command -v "$package" &>/dev/null; then
            echo -e "${gl_kjlan}正在安装 $package...${gl_bai}"
            if command -v dnf &>/dev/null; then
                dnf install -y "$package" || return 1
            elif command -v yum &>/dev/null; then
                yum install -y "$package" || return 1
            elif command -v apt-get &>/dev/null; then
                DEBIAN_FRONTEND=noninteractive apt-get install -y "$package" || return 1
            elif command -v apt &>/dev/null; then
                DEBIAN_FRONTEND=noninteractive apt install -y "$package" || return 1
            elif command -v apk &>/dev/null; then
                apk add "$package" || return 1
            elif command -v pacman &>/dev/null; then
                pacman -S --needed --noconfirm "$package" || return 1
            elif command -v zypper &>/dev/null; then
                zypper install -y "$package" || return 1
            elif command -v opkg &>/dev/null; then
                opkg install "$package" || return 1
            elif command -v pkg &>/dev/null; then
                pkg install -y "$package" || return 1
            else
                echo -e "${gl_hong}未知的包管理器!${gl_bai}"
                return 1
            fi
        else
            echo -e "${gl_lv}${package} 已经安装${gl_bai}"
        fi
    done
}

# ---- 软件包卸载 ----
remove() {
    if [ $# -eq 0 ]; then
        echo -e "${gl_hong}未提供软件包参数!${gl_bai}"
        return 1
    fi

    local package
    for package in "$@"; do
        echo -e "${gl_kjlan}正在卸载 $package...${gl_bai}"
        if command -v dnf &>/dev/null; then
            dnf remove -y "$package" || return 1
        elif command -v yum &>/dev/null; then
            yum remove -y "$package" || return 1
        elif command -v apt-get &>/dev/null; then
            apt-get purge -y "$package" || return 1
        elif command -v apt &>/dev/null; then
            apt purge -y "$package" || return 1
        elif command -v apk &>/dev/null; then
            apk del "$package" || return 1
        elif command -v pacman &>/dev/null; then
            pacman -Rns --noconfirm "$package" || return 1
        elif command -v zypper &>/dev/null; then
            zypper remove -y "$package" || return 1
        elif command -v opkg &>/dev/null; then
            opkg remove "$package" || return 1
        elif command -v pkg &>/dev/null; then
            pkg delete -y "$package" || return 1
        else
            echo -e "${gl_hong}未知的包管理器!${gl_bai}"
            return 1
        fi
    done
}

# ---- 磁盘空间检查 ----
check_disk_space() {
    local required_gb=$1
    local path=${2:-/}
    mkdir -p "$path"
    local required_space_mb=$((required_gb * 1024))
    local available_space_mb
    available_space_mb=$(df -m "$path" | awk 'NR==2 {print $4}')
    if [ "$available_space_mb" -lt "$required_space_mb" ]; then
        echo -e "${gl_huang}提示: ${gl_bai}磁盘空间不足！"
        echo "当前可用空间: $((available_space_mb/1024))G"
        echo "最小需求空间: ${required_gb}G"
        echo "无法继续安装，请清理磁盘空间后重试。"
        return 1
    fi
}

# ---- systemctl 包装 (兼容 Alpine) ----
systemctl() {
    local COMMAND="$1"
    local SERVICE_NAME="$2"
    if command -v apk &>/dev/null; then
        service "$SERVICE_NAME" "$COMMAND"
    else
        /bin/systemctl "$COMMAND" "$SERVICE_NAME"
    fi
}

restart() { systemctl restart "$1"; }
start()   { systemctl start "$1"; }
stop()    { systemctl stop "$1"; }
status()  { systemctl status "$1"; }

enable() {
    local SERVICE_NAME="$1"
    if command -v apk &>/dev/null; then
        rc-update add "$SERVICE_NAME" default
    else
        /bin/systemctl enable "$SERVICE_NAME"
    fi
    echo "$SERVICE_NAME 已设置为开机自启。"
}

# ---- 等待用户按键返回 ----
break_end() {
    echo -e "${gl_lv}操作完成${gl_bai}"
    echo "按任意键继续..."
    read -n 1 -s -r -p ""
    echo ""
    clear
}

# ---- 确认高影响操作 ----
confirm_action() {
    local answer
    read -r -p "${1} [y/N]: " answer
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}

# ---- 检查 ROOT 权限 ----
root_use() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${gl_hong}注意: 请在root用户下运行脚本${gl_bai}"
        return 1
    fi
}

# ---- 停止占用端口的容器或进程 ----
stop_containers_or_kill_process() {
    local port=$1
    local containers
    containers=$(docker ps --filter "publish=$port" --format "{{.ID}}" 2>/dev/null)
    if [ -n "$containers" ]; then
        docker stop $containers
    else
        install lsof
        for pid in $(lsof -t -i:$port 2>/dev/null); do
            kill -9 $pid
        done
    fi
}

# ---- 检查 443 端口占用 ----
check_port() {
    local PORT=443
    local result
    result=$(ss -tulpn 2>/dev/null | grep ":$PORT")
    if [ -n "$result" ]; then
        local is_nginx_container
        is_nginx_container=$(docker ps --format '{{.Names}}' 2>/dev/null | grep 'nginx')
        if [ -n "$is_nginx_container" ]; then
            echo ""
        else
            clear
            echo -e "${gl_hong}端口 $PORT 已被占用，无法安装环境，卸载以下程序后重试！${gl_bai}"
            echo "$result"
            break_end
            return 1
        fi
    fi
    stop_containers_or_kill_process 80
    stop_containers_or_kill_process 443
}

# ---- 开放 iptables 所有端口 ----
iptables_open() {
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
}

# ---- 安装 Docker ----
install_docker() {
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sh
        ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin 2>/dev/null
        systemctl start docker
        systemctl enable docker
    else
        echo "Docker 已经安装"
    fi
}

# ---- 安装 Node.js ----
install_nodejs() {
    if command -v node &>/dev/null; then
        local installed_version
        installed_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        echo -e "${gl_lv}系统中已经安装Nodejs,版本: ${gl_hong}${installed_version}${gl_bai}"
    else
        echo -e "${gl_huang}系统中未安装nodejs，正在为你安装...${gl_bai}"
        if command -v apt &>/dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && install nodejs
        elif command -v dnf &>/dev/null; then
            dnf install -y nodejs npm
        elif command -v yum &>/dev/null; then
            curl -fsSL https://rpm.nodesource.com/setup_21.x | sudo bash - && install nodejs
        elif command -v apk &>/dev/null; then
            apk add nodejs npm
        else
            echo -e "${gl_hong}暂不支持你的系统!${gl_bai}"
            return 1
        fi
    fi
}

# ---- 安装 Java ----
install_java() {
    if command -v java &>/dev/null; then
        local installed_version
        installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo -e "${gl_lv}系统已经安装Java ${gl_huang}${installed_version}${gl_bai}"
    else
        echo -e "${gl_huang}系统中未安装Java，正在为你安装...${gl_bai}"
        if command -v apt &>/dev/null; then
            apt install -y openjdk-17-jdk
        elif command -v yum &>/dev/null; then
            yum install -y java-17-openjdk
        elif command -v dnf &>/dev/null; then
            dnf install -y java-17-openjdk
        elif command -v apk &>/dev/null; then
            apk add openjdk17
        else
            echo -e "${gl_hong}暂不支持你的系统！${gl_bai}"
            return 1
        fi
        echo -e "${gl_lv}Java安装成功${gl_bai}"
    fi
}

# ---- 安装基础依赖 ----
install_dependency() {
    clear
    install wget socat unzip tar
}

# ---- 创建快捷指令 ----
create_shortcut_at() {
    local script_path="$1"
    local entrypoint="$2"
    shift 2

    local entrypoint_path script_target temp_path link_name link_path
    entrypoint_path=$(readlink -f "$entrypoint" 2>/dev/null) || {
        echo "无法解析工具箱入口: $entrypoint" >&2
        return 1
    }
    script_target=$(readlink -f "$script_path" 2>/dev/null || true)

    if [ -L "$script_path" ] && [ "$script_target" = "$entrypoint_path" ]; then
        :
    elif [ -e "$script_path" ] || [ -L "$script_path" ]; then
        if [ ! -f "$script_path" ] ||
            { ! grep -q '^# SSH_TOOLBOX_MANAGED_WRAPPER$' "$script_path" &&
              ! grep -Fq 'SCRIPT_URL="https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh"' "$script_path"; }; then
            printf '保留已有文件，未覆盖快捷入口: %s\n' "$script_path" >&2
            return 0
        fi
        temp_path="${script_path}.tmp.$$"
        if ! printf '#!/bin/bash\n# SSH_TOOLBOX_MANAGED_WRAPPER\nexec bash %q "$@"\n' "$entrypoint_path" > "$temp_path"; then
            rm -f -- "$temp_path"
            return 1
        fi
        chmod 755 "$temp_path" && mv -f -- "$temp_path" "$script_path" || {
            rm -f -- "$temp_path"
            return 1
        }
    else
        temp_path="${script_path}.tmp.$$"
        if ! printf '#!/bin/bash\n# SSH_TOOLBOX_MANAGED_WRAPPER\nexec bash %q "$@"\n' "$entrypoint_path" > "$temp_path"; then
            rm -f -- "$temp_path"
            return 1
        fi
        chmod 755 "$temp_path" && mv -- "$temp_path" "$script_path" || {
            rm -f -- "$temp_path"
            return 1
        }
    fi

    for link_name in "$@"; do
        link_path="$(dirname "$script_path")/${link_name}"
        if [ -L "$link_path" ] && [ "$(readlink -f "$link_path" 2>/dev/null)" = "$(readlink -f "$script_path" 2>/dev/null)" ]; then
            continue
        elif [ -e "$link_path" ] || [ -L "$link_path" ]; then
            printf '保留已有文件，未覆盖快捷命令: %s\n' "$link_path" >&2
            continue
        fi
        ln -s "$script_path" "$link_path" || return 1
    done
    hash -r >/dev/null 2>&1 || true
}

create_shortcut() {
    create_shortcut_at "/usr/local/bin/toolbox.sh" "${SCRIPT_DIR}/toolbox.sh" k K
}

# ---- 服务器重启 ----
server_reboot() {
    read -p "确定要重启服务器吗？(y/n): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        reboot
    fi
}

# ---- 模块加载器 ----
load_module() {
    local module_name="$1"
    if [[ ! "$module_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo -e "${gl_hong}错误: 无效的模块名称${gl_bai}"
        return 1
    fi
    local module_path="${MODULES_DIR}/${module_name}.sh"
    if [ -f "$module_path" ]; then
        source "$module_path"
    else
        echo -e "${gl_hong}错误: 模块 ${module_name}.sh 不存在${gl_bai}"
        return 1
    fi
}

run_module() {
    local module_name="$1"
    local function_name="$2"
    shift 2

    if [[ ! "$function_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo -e "${gl_hong}错误: 无效的模块入口名称${gl_bai}"
        return 1
    fi
    load_module "$module_name" || return 1
    if ! declare -F "$function_name" >/dev/null; then
        echo -e "${gl_hong}错误: 模块 ${module_name}.sh 未定义入口函数 ${function_name}${gl_bai}"
        return 1
    fi
    "$function_name" "$@"
}
