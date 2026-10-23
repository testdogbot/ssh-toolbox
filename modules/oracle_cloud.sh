#!/bin/bash
# ============================================================
# 模块: oracle_cloud (甲骨文云合集)
# 来源: ssh_tool.sh 主菜单选项14 (第5555-5747行)
# 依赖: lib/common.sh (install, break_end, main_menu, 颜色变量)
# ============================================================
oracle_cloud_menu() {
while true; do
    clear
    echo -e "${purple}▶ 甲骨文云IP选优脚本合集${re}"
    echo -e "${green}-----------------------------------${re}"
    echo -e "${green}      IPv4                          ${re}"
    echo -e "${green} 1.  优_ec11 IPV4优先脚本          ${re}"
    echo -e "${green} 2.  优_Gran01_IPV4优选脚本         ${re}"
    echo -e "${green} 3.  优_漏人IPV4优先脚本           ${re}"
    echo -e "${green} 4.  优_matsui IPV4优先脚本         ${re}"
    echo -e "${green} 5.  优_o_1 IPV4优先脚本           ${re}"
    echo -e "${yellow}-----------------------------------${re}"
    echo -e "${yellow}      IPv6                          ${re}"
    echo -e "${yellow} 6.  优_ec11 IPV6优先脚本          ${re}"
    echo -e "${yellow} 7.  优_Gran01_IPV6优选脚本         ${re}"
    echo -e "${yellow} 8.  优_matsui IPV6优先脚本         ${re}"
    echo -e "${yellow} 9.  优_o_1 IPV6优先脚本           ${re}"
    echo -e "${yellow}10.  优_漏人IPV6优先脚本           ${re}"
    echo -e "${purple}-----------------------------------${re}"
    echo -e "${purple}      通用脚本                     ${re}"
    echo -e "${purple}11.  通用_Miller IPV4/IPV6优先脚本 ${re}"
    echo -e "${purple}12.  DD Debian系统脚本(8G以上盘) ${re}"
    echo -e "${purple}13.  DD Debian 13系统脚本          ${re}"
    echo -e "${purple}14.  开启ROOT密码登陆脚本         ${re}"
    echo -e "${purple}15.  开启虚拟内存脚本             ${re}"
    echo -e "${purple}16.  查看虚拟内存脚本             ${re}"
    echo -e "${purple}17.  查看虚拟内存并设置           ${re}"
    echo -e "${purple}18.  重装系统脚本                 ${re}"
    echo -e "${purple}19.  R探长一键开机脚本            ${re}"
    echo -e "${purple}20.  甲骨文ARM重装脚本            ${re}"
    echo "---------------------------"
    echo -e "${skyblue} 0. 返回主菜单${re}"
    echo "---------------------------"
    read -p "$(echo -e ${red}请输入你的选择: ${re})" sub_choice
    case $sub_choice in
        1)  clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv4/Oracle-ec11.sh) ;;
        2)  clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv4/Oracle-Gran01.sh) ;;
        3)  clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv4/Oracle-louren.sh) ;;
        4)  clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv4/Oracle-matsui.sh) ;;
        5)  clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv4/Oracle-o1.sh) ;;
        6)  clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv6/Oracle-ec11-v6.sh) ;;
        7)  clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv6/Oracle-Gran01-v6.sh) ;;
        8)  clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv6/Oracle-matsui-v6.sh) ;;
        9)  clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv6/Oracle-o1-v6.sh) ;;
        10) clear; bash <(curl -sL https://raw.githubusercontent.com/hami176/Oracle-server/main/ipv6/Oracle-louren-v6.sh) ;;
        11) clear; bash <(curl -sL https://raw.githubusercontent.com/iiiiiiiwiraki/Oracle-Keep-IP/pocsu.sh) ;;
        12) clear; bash <(curl -sL https://www.baipiao.eu.org/obi/Download) ;;
        13) clear; bash <(curl -sL https://www.baipiao.eu.org/obi/Download_Debian13) ;;
        14) clear; bash <(curl -sL https://raw.githubusercontent.com/x-os/Pve-Ensure-IP/src/Change-Root-Password.sh) ;;
        15) clear; bash <(curl -sL https://www.baipiao.eu.org/obi/Swap) ;;
        16) clear; bash <(curl -sL https://www.baipiao.eu.org/obi/Swap-check) ;;
        17) clear; bash <(curl -sL https://www.baipiao.eu.org/obi/Swap-set) ;;
        18) clear; bash <(curl -sL https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh) ;;
        19) clear; bash <(curl -sL https://raw.githubusercontent.com/rbiserver/ddate/main/run.sh) ;;
        20) clear; bash <(curl -sL https://gitlab.com/hemajun/agent/-/raw/main/Install.sh) ;;
        0) return 0 ;;
        *) echo "无效的输入!" ;;
    esac
    break_end
done
}
