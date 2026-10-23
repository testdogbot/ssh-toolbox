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
echo -e "${gl_lv} 1. 系统信息查询              11. 节点搭建合集 ▶          ${gl_bai}"
echo -e "${gl_lv} 2. 系统更新                  12. NAT小鸡管理 ▶           ${gl_bai}"
echo -e "${gl_lv} 3. 系统清理                  13. 甲骨文云合集 ▶          ${gl_bai}"
echo -e "${gl_lv} 4. 组件管理 ▶                14. 常用环境管理 ▶          ${gl_bai}"
echo -e "${gl_lv} 5. BBR 加速管理              15. 测试脚本合集 ▶          ${gl_bai}"
echo -e "${gl_lv} 6. Docker 管理 ▶             16. 服务器集群控制 ▶        ${gl_bai}"
echo -e "${gl_lv} 7. WARP 管理 ▶               17. AI 工具管理 ▶           ${gl_bai}"
echo -e "${gl_huang} 8. LDNMP 建站 ▶              18. 网络优化 ▶              ${gl_bai}"
echo -e "${gl_lv} 9. 面板工具与应用 ▶          19. KPanel Web 面板 ▶      ${gl_bai}"
echo -e "${gl_lv}10. 系统工具 ▶                20. 游戏开服脚本 ▶          ${gl_bai}"
echo -e "${gl_kjlan}-------------------------------------------------------------------${gl_bai}"
echo -e "${gl_kjlan}00. 脚本更新     88. 退出脚本${gl_bai}"
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
    echo "1. 现在检查更新"
    echo "2. 开启自动更新"
    echo "3. 关闭自动更新"
    echo "0. 返回主菜单"
    echo "------------------------"
    read -p "请输入你的选择: " sub_choice
    case $sub_choice in
        1)
            clear
            echo "当前项目尚未配置受信任的发布源，无法检查更新。"
            echo "请通过项目发布渠道核实版本后再手动更新。"
            ;;
        2)
            echo "自动更新尚未实现，未更改任何设置。"
            ;;
        3)
            echo "自动更新尚未实现，未更改任何设置。"
            ;;
        0) ;;
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
                "应用市场: toolbox.sh app"
            ;;
        *)
            echo "SSH Toolbox v${TOOLBOX_VERSION}"
            echo "未知命令: $1"
            echo "输入 'toolbox.sh --help' 查看帮助"
            ;;
    esac
fi
