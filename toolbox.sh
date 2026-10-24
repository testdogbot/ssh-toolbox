#!/bin/bash
#=========================================================================
# toolbox.sh - SSH Toolbox 统一主入口
# 整合自 kejilion/sh (v4.5.13, Apache 2.0) 和 eooce/ssh_tool (v8.8.8)
#
# 作者: 整合 by CodeBuddy
# 原作者: 科技lion (kejilion) / 老王 (eooce)
# 许可证: Apache License 2.0
#=========================================================================

TOOLBOX_VERSION="1.0.0"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- 加载公共函数库 ----
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/stats.sh"
source "${SCRIPT_DIR}/lib/i18n.sh"

# ---- 主菜单函数 ----
toolbox_sh() {
root_use || return 1
create_shortcut || return 1
sum_run_times
while true; do
clear
echo -e "    ${gl_kjlan}当日运行：${gl_huang}${STATS_TODAY:-0}次   ${gl_kjlan}累计运行：${gl_huang}${STATS_TOTAL:-0}次${gl_bai}"
echo -e "${gl_hui}----------- SSH Toolbox v${TOOLBOX_VERSION} -----------${gl_bai}"
echo -e "${gl_hui}整合自 kejilion/sh + eooce/ssh_tool${gl_bai}"
echo -e "${gl_hui}许可证: Apache License 2.0${gl_bai}"
echo ""
echo -e "${gl_kjlan} ##  ## #####   ####       ######  ####   ####  ##      ${gl_bai}"
echo -e "${gl_kjlan} ##  ## ##  ## ##            ##   ##  ## ##  ## ##      ${gl_bai}"
echo -e "${gl_kjlan} ##  ## #####   ####.        ##   ##  ## ##  ## ##      ${gl_bai}"
echo -e "${gl_kjlan}  ####  ##         ##        ##   ##  ## ##  ## ##      ${gl_bai}"
echo -e "${gl_kjlan}   ##   ##     ####          ##    ####   ####  ######  ${gl_bai}"
echo ""
echo -e "                 ${gl_huang}SSH Toolbox v${TOOLBOX_VERSION}${gl_bai}"
echo -e "${gl_huang}支持 Ubuntu/Debian/CentOS/Alpine/Fedora/Rocky/Almalinux/Oracle-linux${gl_bai}"
echo ""
echo -e "${gl_kjlan}快捷键已设置为 ${gl_huang}k, ${gl_kjlan}下次运行输入 ${gl_huang}k ${gl_kjlan}可快速启动此脚本${gl_bai}"
echo -e "${gl_kjlan}-------------------------------------------------------------------${gl_bai}"
echo -e "${gl_lv} 1. $(t main_system_info '系统信息查询')      11. $(t main_nodes '节点搭建合集') ▶      ${gl_bai}"
echo -e "${gl_lv} 2. $(t main_system_update '系统更新')          12. $(t main_nat 'NAT小鸡管理') ▶       ${gl_bai}"
echo -e "${gl_lv} 3. $(t main_system_clean '系统清理')          13. $(t main_oracle '甲骨文云合集') ▶      ${gl_bai}"
echo -e "${gl_lv} 4. $(t main_components '组件管理') ▶        14. $(t main_env '常用环境管理') ▶      ${gl_bai}"
echo -e "${gl_lv} 5. $(t main_bbr 'BBR 加速管理')          15. $(t main_tests '测试脚本合集') ▶      ${gl_bai}"
echo -e "${gl_lv} 6. $(t main_docker 'Docker 管理') ▶       16. $(t main_cluster '服务器集群控制') ▶  ${gl_bai}"
echo -e "${gl_lv} 7. $(t main_warp 'WARP 管理') ▶          17. $(t main_ai 'AI 工具管理') ▶         ${gl_bai}"
echo -e "${gl_huang} 8. $(t main_ldnmp 'LDNMP 建站') ▶        18. $(t main_network '网络优化') ▶       ${gl_bai}"
echo -e "${gl_lv} 9. $(t main_panels '面板工具与应用') ▶  19. $(t main_kpanel 'KPanel Web 面板') ▶ ${gl_bai}"
echo -e "${gl_lv}10. $(t main_system_tools '系统工具') ▶    20. $(t main_games '游戏开服脚本') ▶    ${gl_bai}"
echo -e "${gl_kjlan}-------------------------------------------------------------------${gl_bai}"
echo -e "${gl_kjlan}00. $(t main_update '脚本更新')     77. $(t main_language '语言 / Language')     88. $(t main_exit '退出脚本')${gl_bai}"
echo -e "${gl_huang}-------------------------------------------------------------------${gl_bai}"
read -p "$(echo -e ${gl_hong}请输入你的选择: ${gl_bai})" choice

case "$choice" in
  1)  run_module system_info system_info ;;
  2)  root_use && run_module system_manage system_update ;;
  3)  root_use && run_module system_manage system_clean ;;
  4)  run_module component_manage component_manage_menu ;;
  5)  root_use && run_module bbr bbr_menu ;;
  6)  run_module docker_manager docker_menu ;;
  7)  run_module warp_manager warp_menu ;;
  8)  root_use && run_module ldnmp ldnmp_menu ;;
  9)  run_module panel_tools panel_tools_menu ;;
  10) run_module system_tools system_tools_menu ;;
  11) run_module node_setup node_setup_menu ;;
  12) root_use && run_module nat_vm nat_vm_menu ;;
  13) run_module oracle_cloud oracle_cloud_menu ;;
  14) run_module env_manage env_manage_menu ;;
  15) run_module test_scripts test_scripts_menu ;;
  16) run_module cluster cluster_menu ;;
  17) run_module ai_tools ai_tools_menu ;;
  18) run_module network_optimize network_optimize_menu ;;
  19) run_module kpanel kpanel_menu ;;
  20) run_module games_server games_server_menu ;;
  00) toolbox_update ;;
  77) choose_language ;;
  88) clear; exit ;;
  *)  echo "无效的输入!" ;;
esac
break_end
done
}

# ---- 脚本更新 ----
toolbox_update() {
    clear
    echo -e "${gl_kjlan}当前版本: v${TOOLBOX_VERSION}${gl_bai}"
    echo "------------------------"
    echo "1. 检查并安装最新版本"
    echo "0. 返回主菜单"
    echo "------------------------"
    read -p "请输入你的选择: " sub_choice
    case $sub_choice in
        1)
            clear
            if [ ! -f "${SCRIPT_DIR}/.ssh-toolbox-managed" ]; then
                echo "当前目录不是由安装器管理的安装，无法安全地原位更新。"
                echo "请从短域名或 GitHub 安装入口重新运行安装器。"
                return 1
            fi
            echo "正在从 GitHub main 分支更新工具箱；旧版本会保留为备份。"
            bash "${SCRIPT_DIR}/install.sh" --update "$SCRIPT_DIR"
            return $?
            ;;
        0) ;;
        *) echo "无效的输入。" ;;
    esac
}

# ---- 命令行参数处理 ----
if [ "$#" -eq 0 ]; then
    toolbox_sh
else
    case "$1" in
        install|add|安装)
            root_use && { shift; install "$@"; } ;;
        remove|del|uninstall|卸载)
            root_use && { shift; remove "$@"; } ;;
        update|更新)
            root_use && run_module system_manage system_update ;;
        clean|清理)
            root_use && run_module system_manage system_clean ;;
        dd|重装)
            run_module system_tools dd_xitong ;;
        bbr3|bbrv3)
            run_module bbr bbrv3 ;;
        info)
            run_module system_info system_info ;;
        docker)
            case "${2:-}" in
                ps|容器) run_module docker_manager docker_ps ;;
                img|镜像) run_module docker_manager docker_image ;;
                install|安装) root_use && install_docker ;;
                *) run_module docker_manager docker_menu ;;
                esac
            ;;
        ssl)
            if [ "${2:-}" = "ps" ]; then
                run_module ssl_cert ssl_ps
            else
                root_use && run_module ssl_cert add_ssl
            fi ;;
        app)
            run_module app_market app_market_menu ;;
        kpanel)
            run_module kpanel kpanel_menu ;;
        fail2ban|f2b)
            run_module website_security fail2ban_panel ;;
        sshkey)
            run_module system_tools sshkey_panel ;;
        help|--help|-h|帮助)
            printf '%s\n' \
                "SSH Toolbox v${TOOLBOX_VERSION}" \
                "启动菜单: toolbox.sh" \
                "系统信息: toolbox.sh info" \
                "安装软件包: toolbox.sh install nano wget" \
                "卸载软件包: toolbox.sh remove nano wget" \
                "更新系统: toolbox.sh update" \
                "Docker管理: toolbox.sh docker [ps|img|install]" \
                "应用市场: toolbox.sh app" \
                "语言设置: 在主菜单选择 77，或设置 SSH_TOOLBOX_LANG=cn|en"
            ;;
        *)
            echo "SSH Toolbox v${TOOLBOX_VERSION}"
            echo "未知命令: $1"
            echo "输入 'toolbox.sh --help' 查看帮助"
            ;;
    esac
fi
