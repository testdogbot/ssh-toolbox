#!/bin/bash
# ============================================================
# 模块: component_manage (组件管理)
# 来源: ssh_tool.sh 主菜单选项4 (第737-989行)
# 依赖: lib/common.sh (install, remove, break_end, main_menu, 颜色变量)
# ============================================================
component_manage_menu() {
while true; do
    clear
    echo "▶ 组件管理"
    echo "------------------------"
    echo " 1. curl 下载工具"
    echo " 2. wget 下载工具"
    echo " 3. sudo 超级管理权限工具"
    echo " 4. socat 通信连接工具 （申请域名证书必备）"
    echo " 5. htop 系统监控工具"
    echo " 6. iftop 网络流量监控工具"
    echo " 7. unzip ZIP压缩解压工具"
    echo " 8. tar GZ压缩解压工具"
    echo " 9. tmux 多路后台运行工具"
    echo "10. ffmpeg 视频编码直播推流工具"
    echo "11. btop 现代化监控工具"
    echo "12. ranger 文件管理工具"
    echo "13. gdu 磁盘占用查看工具"
    echo "14. fzf 全局搜索工具"
    echo "15. screen后台会话工具"
    echo "16. masscan端口快速扫描工具"
    echo "------------------------"
    echo "21. cmatrix 黑客帝国屏保"
    echo "22. sl 跑火车屏保"
    echo "------------------------"
    echo "26. 俄罗斯方块小游戏"
    echo "27. 贪吃蛇小游戏"
    echo "28. 太空入侵者小游戏"
    echo "------------------------"
    echo "31. 全部安装"
    echo -e "${red}32. 全部卸载${re}"
    echo "------------------------"
    echo -e "${yellow}41. 安装指定工具${re}"
    echo -e "${red}42. 卸载指定工具${re}"
    echo "------------------------"
    echo -e "${skyblue} 0. 返回主菜单${re}"
    echo "------------------------"
    read -p "$(echo -e ${red}请输入你的选择: ${re})" sub_choice

    case $sub_choice in
        1)  clear; install curl; clear; echo "工具已安装，使用方法如下："; curl --help ;;
        2)  clear; install wget; clear; echo "工具已安装，使用方法如下："; wget --help ;;
        3)  clear; install sudo; clear; echo "工具已安装，使用方法如下："; sudo --help ;;
        4)  clear; install socat; clear; echo "工具已安装，使用方法如下："; socat -h ;;
        5)  clear; install htop; clear; htop ;;
        6)  clear; install iftop; clear; iftop ;;
        7)  clear; install unzip; clear; echo "工具已安装，使用方法如下："; unzip ;;
        8)  clear; install tar; clear; echo "工具已安装，使用方法如下："; tar --help ;;
        9)  clear; install tmux; clear; echo "工具已安装，使用方法如下："; tmux --help ;;
        10) clear; install ffmpeg; clear; echo "工具已安装，使用方法如下："; ffmpeg --help ;;
        11) clear; install btop; clear; btop ;;
        12) clear; install ranger; cd /; clear; ranger; cd ~ ;;
        13) clear; install gdu; cd /; clear; gdu; cd ~ ;;
        14) clear; install fzf; cd /; clear; fzf; cd ~ ;;
        15)
            clear
            if [ -f /etc/os-release ]; then
                os_name=$(grep '^ID=' /etc/os-release | cut -d= -f2)
            elif command -v lsb_release > /dev/null 2>&1; then
                os_name=$(lsb_release -i | cut -f2)
            else
                echo "无法确定操作系统类型。"; exit 1
            fi
            os_name=$(echo $os_name | tr -d '"')
            if [ "$os_name" = "centos" ] || [ "$os_name" = "rocky" ]; then
                yum install epel-release -y; yum install screen -y
            elif [ "$os_name" = "amzn" ]; then
                amazon-linux-extras install epel; yum install screen -y
            else
                install screen
            fi
            cd ~
            ;;
        16)
            clear
            if [ -f /etc/os-release ]; then
                os_name=$(grep '^ID=' /etc/os-release | cut -d= -f2)
            elif command -v lsb_release > /dev/null 2>&1; then
                os_name=$(lsb_release -i | cut -f2)
            else
                echo "无法确定操作系统类型。"; exit 1
            fi
            os_name=$(echo $os_name | tr -d '"')
            if [ "$os_name" = "centos" ] || [ "$os_name" = "rocky" ]; then
                yum install epel-release -y; yum install masscan -y
            elif [ "$os_name" = "amzn" ]; then
                amazon-linux-extras install epel; yum install masscan -y
            else
                install masscan
            fi
            cd ~
            ;;
        21) clear; install cmatrix; clear; cmatrix ;;
        22) clear; install sl; clear; /usr/games/sl ;;
        26) clear; install bastet; clear; /usr/games/bastet ;;
        27) clear; install nsnake; clear; /usr/games/nsnake ;;
        28) clear; install ninvaders; clear; /usr/games/ninvaders ;;
        31) clear; install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger gdu fzf cmatrix sl bastet nsnake ninvaders ;;
        32) clear; remove htop iftop unzip tmux ffmpeg btop ranger gdu fzf cmatrix sl bastet nsnake ninvaders ;;
        41) clear; read -p "请输入安装的工具名（wget curl sudo htop）: " installname; install $installname ;;
        42) clear; read -p "请输入卸载的工具名（htop ufw tmux cmatrix）: " removename; remove $removename ;;
        0)  return 0 ;;
        *)  echo "无效的输入!" ;;
    esac
    break_end
done
}
