#!/bin/bash
# ============================================================
# 模块: warp_manager (WARP 管理)
# 来源: ssh_tool.sh 主菜单选项7 (第1364-1368行)
# 依赖: lib/common.sh (install, break_end)
# 功能: 下载执行 fscarmen 的 WARP 脚本，解锁 ChatGPT/Netflix
# ============================================================
warp_menu() {
    clear
    install wget
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]
}
