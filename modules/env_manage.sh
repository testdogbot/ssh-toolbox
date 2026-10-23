#!/bin/bash
# ============================================================
# 模块: env_manage (常用环境管理)
# 来源: ssh_tool.sh 主菜单选项15 (第5749-6205行)
# 依赖: lib/common.sh (install, remove, install_nodejs, install_java, break_end, main_menu, 颜色变量)
# ============================================================
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
                sleep 2; main_menu
            fi
            VERSION=$(python3 -V 2>&1 | awk '{print $2}')
            PY_VERSION=$(curl -s https://www.python.org/ | grep "downloads/release" | grep -o 'Python [0-9.]*' | grep -o '[0-9.]*')
            if [[ $VERSION == "3"* ]]; then
                if [ "$VERSION" = "$PY_VERSION" ]; then
                    echo -e "${green}检测到你的Python3版本已经是最新版本:${red}${PY_VERSION}${green}，无需安装或升级${re}"
                    sleep 2; main_menu
                else
                    echo -e "${yellow}检测到你的Python3版本:${red}${VERSION}${yellow},最新版本:${green}${PY_VERSION}${re}"
                    read -p "$(echo -e ${red}是否确认升级最新版Python3？[y/n]: ${re})" confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        if [[ $OS == "CentOS" ]]; then
                            yum remove python3 -y; package-cleanup --leaves; package-cleanup --orphans; yum autoremove -y
                            rm -rf /usr/local/python3* >/dev/null 2>&1
                        elif [[ $OS == "Alpine" ]]; then
                            apk del python3; rm -rf /usr/lib/python3.* /etc/python3 /var/cache/apk/*
                        elif [[ $OS == "Fedora" ]] || [[ $OS == "Rocky" ]] || [[ $OS == "AlmaLinux" ]] || [[ $OS == "Amazon" ]]; then
                            dnf remove python3 -y; dnf autoremove -y; rm -rf ~/.local/lib/python3.*
                        else
                            apt --purge remove python3 python3-pip -y; rm -rf /usr/local/python3*
                        fi
                    else
                        echo -e "${yellow}已取消升级Python3${re}"; sleep 1; main_menu
                    fi
                fi
            else
                echo -e "${red}检测到没有安装Python3。${re}"
                read -p "$(echo -e ${red}是否确认安装最新版Python3？[y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    echo -e "${green}开始安装最新版Python3...${re}"
                else
                    echo -e "${yellow}已取消安装Python3${re}"; exit 1
                fi
            fi
            if [[ $OS == "CentOS" ]]; then
                yum update -y; yum groupinstall -y "development tools"; yum install wget tar openssl-devel bzip2-devel libffi-devel zlib-devel -y
            elif [[ $OS == "Fedora" ]] || [[ $OS == "Rocky" ]] || [[ $OS == "AlmaLinux" ]] || [[ $OS == "Amazon" ]]; then
                dnf update -y; dnf groupinstall -y "development tools"; dnf install wget tar openssl-devel bzip2-devel libffi-devel zlib-devel -y
            elif [[ $OS == "Alpine" ]]; then
                apk update; apk add python3 py3-pip wget tar openssl-dev bzip2-dev libffi-dev zlib-dev; sleep 2; break_end; main_menu
            else
                apt update -y; apt install wget tar build-essential libreadline-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev -y
            fi
            install wget tar; cd /root/
            wget https://www.python.org/ftp/python/${PY_VERSION}/Python-"$PY_VERSION".tgz
            tar -zxf Python-${PY_VERSION}.tgz; cd Python-${PY_VERSION}
            ./configure --prefix=/usr/local/python3; make -j $(nproc); make install
            if [ $? -eq 0 ]; then
                rm -f /usr/local/bin/python3* /usr/local/bin/pip3*
                ln -sf /usr/local/python3/bin/python3 /usr/bin/python3
                ln -sf /usr/local/python3/bin/pip3 /usr/bin/pip3
                clear; echo -e "${yellow}Python3安装${green}成功，${re}版本为: ${green}${PY_VERSION}${re}"; sleep 2
            else
                clear; echo -e "${red}Python3安装失败！${re}"; exit 1
            fi
            cd /root/ && rm -rf Python-${PY_VERSION}.tgz Python-${PY_VERSION}
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
                    sleep 2; main_menu
                else
                    echo -e "${yellow}你的nodejs版本是${re}${red}${current_version}${re}，${yellow}最新版本是${purple}${latest_version}${re}"
                    read -p "$(echo -e ${red}是否卸载旧版nodejs并安装最新版？[y/n]: ${re})" confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        remove nodejs; sleep 1; install_nodejs
                    else
                        main_menu
                    fi
                fi
            else
                install_nodejs; break_end
            fi
            ;;
        3)
            clear
            html=$(curl -s https://go.dev/dl/)
            latest_version=$(echo "$html" | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
            architecture=$(uname -m)
            case "$architecture" in
                x86_64|amd64) latest_version_url="https://golang.org/dl/${latest_version}.linux-amd64.tar.gz" ;;
                x86)          latest_version_url="https://golang.org/dl/${latest_version}.linux-386.tar.gz" ;;
                arm64|aarch64) latest_version_url="https://golang.org/dl/${latest_version}.linux-arm64.tar.gz" ;;
                *) echo -e "${red}暂不支持的系统架构：$architecture${re}"; sleep 2; main_menu ;;
            esac
            if command -v go &> /dev/null; then
                installed_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+')
                echo -e "${yellow}当前已安装的Go版本：${red}$installed_version${re}"
                if [ "$installed_version" = "$latest_version" ]; then
                    echo -e "${green}当前Go已经是最新版本，无需更新。${re}"; sleep 2; main_menu
                else
                    echo -e "${yellow}发现新版本：$latest_version。${re}"
                    read -p "$(echo -e ${red}需要卸载当前版本 $installed_version 并安装新版本 $latest_version 吗 [y/n]: ${re})" confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        echo "卸载旧版Go：$installed_version"; rm -rf /usr/local/go
                    else
                        echo -e "${yellow}退出更新。${re}"; sleep 2; break_end
                    fi
                fi
            else
                echo -e "${yellow}系统中未安装Go，正在为你安装最新版Go...${re}"
            fi
            install tar
            wget -O go_latest.tar.gz "$latest_version_url"
            tar -C /usr/local -xzf go_latest.tar.gz
            GO_PATH="/usr/local/go/bin"
            if [[ ":$PATH:" != *":${GO_PATH}:"* ]]; then
                if grep -qi alpine /etc/os-release; then
                    echo "export PATH=${GO_PATH}:\$PATH" > /etc/profile.d/go.sh
                    chmod +x /etc/profile.d/go.sh; source /etc/profile.d/go.sh
                else
                    echo "export PATH=${GO_PATH}:\$PATH" | tee -a /etc/profile > /dev/null
                    source /etc/profile
                fi
            fi
            rm go_latest.tar.gz
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
                    echo -e "${green}当前已安装Java最新版：${yellow}${latest_version},无需更新${re}"; sleep 2; main_menu
                else
                    read -p "$(echo -e ${red}是否卸载旧版java并安装最新版？[y/n]: ${re})" confirm
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        remove java; sleep 2; install_java
                    else
                        main_menu
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
                    remove python3
                    rm -rf /usr/bin/pip3 /usr/bin/python3 /usr/share/python3 /usr/local/python3 /usr/share/man/man1/python3.1.gz /usr/local/bin/python /usr/local/lib/python* /usr/local/bin/python*
                    echo -e "${green}python已卸载${re}"; break_end
                else
                    main_menu
                fi
            else
                echo -e "${yellow}系统中未安装python，无需卸载${re}"; sleep 2; main_menu
            fi
            ;;
        6)
            clear
            if command -v node &>/dev/null; then
                current_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
                echo -e "${yellow}当前已安装nodejs${red}$current_version${re}"
                read -p "$(echo -e ${red}确定卸载nodejs？[y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    remove nodejs npm
                    rm -rf ~/.npm ~/.nvm /usr/local/bin/node /usr/local/lib/node_modules
                    echo -e "${green}nodejs已卸载${re}"; break_end
                else
                    main_menu
                fi
            else
                echo -e "${yellow}系统中未安装nodejs，无需卸载${re}"; sleep 2; main_menu
            fi
            ;;
        7)
            clear
            if command -v go &> /dev/null; then
                installed_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+' | cut -c 3-)
                echo -e "${yellow}当前已安装Go：${red}$installed_version${re}"
                read -p "$(echo -e ${red}确定卸载Go？[y/n]: ${re})" confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    rm -rf /usr/local/go
                    export PATH=$PATH:/usr/local/go/bin
                    export GOPATH=$HOME/go
                    export PATH=$PATH:$GOPATH/bin
                    source ~/.bashrc && source ~/.profile && source ~/.bash_profile
                    echo -e "${green}Go已卸载${re}"; sleep 1; break_end
                else
                    main_menu
                fi
            else
                echo -e "${yellow}系统中未安装Go，无需卸载${re}"; sleep 2; main_menu
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
                        apt remove -y openjdk-17-jdk && apt autoremove -y openjdk-17-jdk
                    elif command -v yum &>/dev/null; then
                        yum remove -y java && yum autoremove -y java
                    elif command -v dnf &>/dev/null; then
                        dnf remove -y java && dnf autoremove -y java
                    elif command -v apk &>/dev/null; then
                        apk del openjdk17
                    fi
                    rm -rf /usr/lib/jvm/java-* /usr/local/java /opt/java
                    echo -e "${green}Java卸载成功！${re}"
                    read -p "$(echo -e ${red}重启服务器配置才可生效，需要立即重启吗 [y/n]: ${re})" confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        sleep 1; reboot
                    else
                        main_menu
                    fi
                else
                    main_menu
                fi
            else
                echo -e "${yellow}系统中未安装Java，无需卸载${re}"; sleep 2
            fi
            ;;
        0) main_menu ;;
        *) echo -e "${yellow}无效的输入!${re}" ;;
    esac
done
}
