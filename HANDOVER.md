# SSH Toolbox 项目交接文档

> 整合自 [kejilion/sh](https://github.com/kejilion/sh) (v4.5.13) 和 [eooce/ssh_tool](https://github.com/eooce/ssh_tool) (v8.8.8)
> 创建日期：2026-10-24
> 许可证：Apache License 2.0

---

## 一、项目概述

将两个 VPS Shell 脚本工具箱整合为统一的模块化项目。

### 关键背景

- **eooce/ssh_tool 是 kejilion/sh 的 Fork**（GitHub 确认 `fork: true`），两者共享代码基础
- kejilion/sh 功能更完善（1.1MB），有 Apache 2.0 License、多语言支持、KPanel、应用市场
- ssh_tool 在 Fork 基础上扩展了节点搭建、NAT小鸡、甲骨文云、WARP 等功能

### 整合策略

| 维度 | 策略 |
|------|------|
| 基础框架 | 以 kejilion/sh 为基础（功能完善、有 License） |
| 重叠功能 | 取 kejilion 更优实现 |
| ssh_tool 独有 | 全部保留，作为模块化插件 |
| kejilion 独有 | 全部保留 |
| 架构 | 模块化拆分，从单文件改为多文件 `source` 加载 |

---

## 二、当前完成状态

### 当前进度（截至 2026-10-24）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 克隆源仓库 + 代码分析 | ✅ 完成 | 下载了 kejilion.sh(1.1MB)、ssh_tool.sh(283KB)、menu.sh(160KB) 及 40+ 辅助文件到 `D:/temp/` |
| 2 | 创建项目目录结构 | ✅ 完成 | 在 `D:/ssh-toolbox/` 下创建了 modules/、lib/、config/、i18n/、apps/、scripts/ 目录 |
| 3 | 构建核心框架 | ✅ 完成 | 创建了 `toolbox.sh`(7.1KB)、`lib/common.sh`(11.1KB)、`lib/stats.sh`(1.5KB)、`lib/i18n.sh`(1.4KB) |
| 4 | ssh_tool 独有模块 | ✅ 完成 | 7个模块文件：component_manage、warp_manager、node_setup、test_scripts、oracle_cloud、env_manage、nat_vm |
| 5 | 重叠功能模块 | ✅ 基础入口完成 | 11 个模块已创建；按系统能力范围实现，不等同于上游全量功能 |
| 6 | 独有功能模块 | 🔶 部分完成 | AI、网络优化、游戏、集群和应用入口已创建；KPanel 自动部署与完整应用目录仍待可信模板 |
| 7 | 文档编写 | ✅ 基础文档完成 | README.md、CONTRIBUTING.md、update_log.sh 已有 |
| 8 | 交接文档 | ✅ 本次 | 本文档 |

`tests/test_module_smoke.sh` 已通过 Git Bash 验证所有 Bash 文件语法和主菜单模块函数加载。Linux VPS 上的交互、服务及系统修改测试尚未执行。

公开仓库时提供 `install.sh` 作为一行命令安装入口：`bash <(curl -fsSL https://raw.githubusercontent.com/testdogbot/ssh-toolbox/main/install.sh)`。它下载 GitHub `main` 分支至 `/opt/ssh-toolbox`（sudo）或 `~/.local/share/ssh-toolbox`（普通用户），更新前备份受管理目录并拒绝覆盖非受管理目录。

短命令 `bash <(curl -Ls ssh-toolbox.alebot.ggff.net)` 由 `cloudflare/worker.mjs` 返回安装脚本，`wrangler.toml` 绑定 Cloudflare Custom Domain。Worker 已单测；域名 Custom Domain 和 TLS 仍需由有权管理 `alebot.ggff.net` Cloudflare Zone 的维护者运行 `npx wrangler login`、`npx wrangler deploy` 后激活。未部署 Worker 前，短域名根路径不可视为已配置。

核心路径优化记录：只读命令和帮助不再要求 root；root 检查仅用于交互菜单及系统修改命令；`run_module` 在模块或入口加载失败时停止分派；安装包不再为每个工具触发全量系统更新，且包管理器失败会直接返回。测试覆盖 CLI 帮助/信息、模块失败保护、包安装错误传播及默认禁用统计。

### 当前项目文件清单

```
D:/ssh-toolbox/                          (项目根目录)
├── toolbox.sh                 7.1KB     ✅ 主入口 + 统一主菜单(20项) + 命令行参数
├── LICENSE                   11.1KB     ✅ Apache License 2.0
├── CONTRIBUTING.md            1.1KB     ✅ 贡献指南
│
├── lib/                                 ✅ 公共函数库
│   ├── common.sh             11.1KB     ✅ 颜色定义、install/remove、ip_address、
│   ├── i18n.sh                1.4KB     ✅ 多语言支持函数
│   └── stats.sh               1.5KB     ✅ 统计功能(默认关闭)
│
├── modules/                             ✅ 24 个模块文件
│   ├── component_manage.sh    5.3KB     ✅ [ssh_tool] 组件管理+小游戏
│   ├── env_manage.sh         14.9KB     ✅ [ssh_tool] Python/Node/Go/Java安装卸载
│   ├── nat_vm.sh             15.7KB     ✅ [ssh_tool] KVM/LXC/Docker/Incus小鸡
│   ├── node_setup.sh         17.0KB     ✅ [ssh_tool] 18种代理节点搭建
│   ├── oracle_cloud.sh        4.6KB     ✅ [ssh_tool] 甲骨文云IP选优+工具
│   ├── test_scripts.sh        2.8KB     ✅ [ssh_tool] 13种测试脚本
│   ├── warp_manager.sh        0.5KB     ✅ [ssh_tool] WARP管理
│   │
│   ├── system_info.sh             ✅ [重叠] 系统信息概览
│   ├── system_manage.sh           ✅ [重叠] 系统更新/清理
│   ├── docker_manager.sh          ✅ [重叠] Docker 管理
│   ├── ldnmp.sh                   ✅ [重叠] 调用本地 LDNMP 脚本并提示风险
│   ├── website_security.sh        ✅ [重叠] Fail2ban 状态及 Cloudflare 辅助脚本入口
│   ├── firewall.sh                ✅ [重叠] IPv4 INPUT TCP 规则管理
│   ├── ssl_cert.sh                ✅ [重叠] Certbot 证书管理
│   ├── bbr.sh                     ✅ [重叠] 内核自带 BBR 管理
│   ├── backup_migrate.sh          ✅ [重叠] 目录备份/恢复
│   ├── panel_tools.sh             ✅ [重叠] 面板容器、官方链接及应用入口
│   ├── system_tools.sh            ✅ [重叠] SSH、DNS、Swap、防火墙及备份入口
│   │
│   ├── ai_tools.sh                ✅ [kejilion] AI 工具脚本入口
│   ├── network_optimize.sh        ✅ [kejilion] 网络优化脚本入口
│   ├── kpanel.sh                  🔶 [kejilion] 状态查询；未提供自动部署器
│   ├── app_market.sh              🔶 本地 apps/*.sh 脚本入口；目录当前为空
│   ├── games_server.sh            ✅ [kejilion] 游戏管理脚本入口
│   └── cluster.sh                 ✅ [ssh_tool] SSH config 别名连接
│
├── config/                    11个文件   ✅ 配置文件
│   ├── nginx.local            0.9KB     Nginx配置
│   ├── www.conf               21.6KB    Nginx站点配置
│   ├── www-1.conf             21.6KB    Nginx站点配置(备份)
│   ├── sshd.local             0.1KB     SSH配置
│   ├── cloudflare.conf        3.1KB     Cloudflare配置
│   ├── fail2ban-nginx-cc.conf 0.5KB     Fail2ban防护
│   ├── custom_mysql_config.cnf 2.0KB    MySQL配置
│   ├── custom_mysql_config-1.cnf 1.1KB MySQL配置(备份)
│   ├── optimized_php.ini      0.8KB     PHP优化配置
│   ├── valkey.conf            0.5KB     Valkey配置
│   └── archive.key            1.7KB     归档密钥
│
├── scripts/                  24个文件   ✅ 独立辅助脚本
│   ├── ldnmp.sh              2.8KB      LDNMP安装脚本
│   ├── beifen.sh             0.4KB      备份脚本
│   ├── network-optimize.sh   19.3KB     网络优化
│   ├── upgrade_openssh9.8p1.sh 4.0KB    SSH升级
│   ├── CF-Under-Attack.sh    2.1KB      CF防护模式
│   ├── Limiting_Shut_down.sh 0.9KB      限流关机
│   ├── TG-SSH-check-notify.sh 0.9KB     TG通知
│   ├── TG-check-notify.sh    3.1KB      TG通知
│   ├── auto_cert_renewal.sh  5.7KB      证书自动续期
│   ├── ai_cli_manager.sh     16.3KB     AI CLI管理
│   ├── deepseek_harness_manager.sh 29.4KB DeepSeek管理
│   ├── hermes_manager.sh     43.2KB     Hermes管理
│   ├── palworld.sh           12.5KB     幻兽帕鲁服务器
│   ├── mc.sh                 13.2KB     Minecraft服务器
│   ├── translate.py          3.3KB      翻译工具
│   └── ... (8个其他辅助脚本)
│
├── i18n/                                🔶 基础翻译键已创建
│   ├── cn/messages.sh                    简体中文
│   └── en/messages.sh                    English
│
└── apps/                      [空]      本地应用市场目录
```

---

## 三、统一主菜单结构

`toolbox.sh` 中的主菜单（20项）：

| 编号 | 菜单项 | 来源 | 模块文件 | 状态 |
|------|--------|------|----------|------|
| 1 | 系统信息查询 | 重叠 | modules/system_info.sh | ✅ |
| 2 | 系统更新 | 重叠 | modules/system_manage.sh | ✅ |
| 3 | 系统清理 | 重叠 | modules/system_manage.sh | ✅ |
| 4 | 组件管理 ▶ | ssh_tool | modules/component_manage.sh | ✅ |
| 5 | BBR 加速管理 | 重叠 | modules/bbr.sh | ✅ |
| 6 | Docker 管理 ▶ | 重叠 | modules/docker_manager.sh | ✅ |
| 7 | WARP 管理 ▶ | ssh_tool | modules/warp_manager.sh | ✅ |
| 8 | LDNMP 建站 ▶ | 重叠 | modules/ldnmp.sh | ✅ |
| 9 | 面板工具与应用 ▶ | 重叠 | modules/panel_tools.sh | ✅ |
| 10 | 系统工具 ▶ | 重叠 | modules/system_tools.sh | ✅ |
| 11 | 节点搭建合集 ▶ | ssh_tool | modules/node_setup.sh | ✅ |
| 12 | NAT小鸡管理 ▶ | ssh_tool | modules/nat_vm.sh | ✅ |
| 13 | 甲骨文云合集 ▶ | ssh_tool | modules/oracle_cloud.sh | ✅ |
| 14 | 常用环境管理 ▶ | ssh_tool | modules/env_manage.sh | ✅ |
| 15 | 测试脚本合集 ▶ | ssh_tool | modules/test_scripts.sh | ✅ |
| 16 | 服务器集群控制 ▶ | ssh_tool | modules/cluster.sh | ✅ |
| 17 | AI 工具管理 ▶ | kejilion | modules/ai_tools.sh | ✅ |
| 18 | 网络优化 ▶ | kejilion | modules/network_optimize.sh | ✅ |
| 19 | KPanel Web 面板 ▶ | kejilion | modules/kpanel.sh | 🔶 状态查询；自动部署待补 |
| 20 | 游戏开服脚本 ▶ | kejilion | modules/games_server.sh | ✅ |
| 00 | 脚本更新 | - | (toolbox.sh 内置) | ✅ |
| 88 | 退出 | - | (toolbox.sh 内置) | ✅ |

---

## 四、源文件位置（临时下载）

原始脚本和辅助文件已下载到 `D:/temp/` 目录：

| 文件 | 路径 | 大小 | 用途 |
|------|------|------|------|
| kejilion.sh | D:/temp/kejilion.sh | 1.06MB | kejilion 主脚本，供后续核对上游功能 |
| ssh_tool.sh | D:/temp/ssh_tool.sh | 283KB | ssh_tool 主脚本，已提取完成 |
| menu.sh | D:/temp/menu.sh | 156KB | WARP 管理脚本(fscarmen) |
| index.js | D:/temp/index.js | 2.5KB | Node.js 服务 |
| kejilion_files/ | D:/temp/kejilion_files/ | - | kejilion 辅助文件(30+个) |
| ssh_files/ | D:/temp/ssh_files/ | - | ssh_tool 辅助文件 |

### 源脚本代码结构分析

#### kejilion.sh (约 33092 行)

| 函数 | 行号范围 | 功能 |
|------|----------|------|
| 颜色变量、版本号 | 1-12 | `gl_hui`, `gl_hong`, `gl_lv` 等 |
| 全局变量 | 15-23 | `canshu`, `permission_granted`, `ENABLE_STATS` |
| KPanel并发锁 | 27-108 | `kpanel_app_with_lock`, `kpanel_app_update_marker` |
| `quanju_canshu()` | 111-126 | GitHub 代理设置 |
| `send_stats()` | 163-179 | 统计功能 |
| `ip_address()` | 244-270 | IP获取 |
| `install()` | 274-340 | 包安装(8种包管理器) |
| `remove()` | 343-380 | 包卸载 |
| `check_disk_space()` | 390-405 | 磁盘检查 |
| `break_end()` | 437-442 | 等待按键 |
| `install_docker()` | 492-500 | Docker安装 |
| `install_nodejs()` | 502-520 | Node.js安装 |
| `install_java()` | 522-540 | Java安装 |
| `create_shortcut()` | 547-560 | 快捷指令 |
| `docker_ps()` | ~700-900 | Docker容器管理 |
| `docker_image()` | ~900-1050 | Docker镜像管理 |
| `add_ssl()` | ~2000-2300 | SSL证书申请 |
| `install_ldnmp()` | ~2500-2800 | LDNMP建站 |
| `iptables_panel()` | ~3000-3200 | 防火墙管理 |
| `fail2ban_panel()` | ~3400-3600 | 网站防御 |
| `kejilion_sh()` | ~33092 | 主菜单 |

#### ssh_tool.sh (约 6979 行)

| 函数/模块 | 行号范围 | 功能 | 提取状态 |
|-----------|----------|------|----------|
| 颜色变量 | 1-10 | `re`, `red`, `white` 等 | ✅ |
| `ip_address()` | 11-60 | IP获取 | ✅ |
| `install()` | 61-160 | 包安装 | ✅ |
| 主菜单 | 523-620 | 16项+00+88 | ✅ |
| 选项4: 组件管理 | 737-989 | 工具+小游戏 | ✅ |
| 选项7: WARP管理 | 1364-1368 | fscarmen脚本 | ✅ |
| 选项12: 节点搭建 | 5068-5456 | 18种代理 | ✅ |
| 选项13: 测试脚本 | 5458-5553 | 13种测试 | ✅ |
| 选项14: 甲骨文云 | 5555-5747 | 20项工具 | ✅ |
| 选项15: 环境管理 | 5749-6205 | Python/Node/Go/Java | ✅ |
| 选项16: NAT小鸡 | 6207-6956 | KVM/LXC/Docker/Incus | ✅ |

---

## 五、后续工作与能力边界

### 5.1 已补齐的模块入口

重叠功能的 11 个模块和独有功能的 6 个模块文件均已创建。主菜单 20 个入口可加载并解析；AI、网络优化、游戏及 WARP 等入口调用项目内已有脚本。Docker、系统更新/清理、基础防火墙、Certbot、BBR、备份恢复和 SSH 集群功能提供独立实现。

### 5.2 尚未完成的功能

- KPanel 自动部署：当前没有随项目提供、经核实的安装模板；入口只检查容器和显示说明。
- 应用市场：`apps/` 目录目前为空，只允许运行本地 `.sh` 文件；没有恢复上游应用目录。
- 多语言：`i18n/cn/messages.sh` 和 `i18n/en/messages.sh` 已建立基础键，主菜单仍以中文为主，尚未完成全量接入。
- 在线更新/自动更新：未配置可信发布源，界面明确告知不可用，不会假报“已是最新”或修改自动更新设置。
- 破坏性功能：系统重装未集成；LDNMP 上游脚本会变更系统和防火墙，入口会提示并要求确认。

### 5.3 验证状态

运行 `bash tests/test_module_smoke.sh` 可检查 Bash 文件语法和主菜单模块函数加载。当前已在 Windows Git Bash 通过；尚未在 Linux VPS 验证交互菜单、包管理器、systemd、iptables、Docker 或实际安装流程。

---

## 六、关键技术决策记录

| 决策点 | 选择 | 原因 |
|--------|------|------|
| 基础框架 | kejilion/sh | 功能更完善、有 License、多语言、KPanel |
| 模块化方式 | `source` 按需加载 | 原项目单文件1.4MB过大，拆分提升可维护性 |
| 颜色变量 | 兼容两套 | 同时保留 `gl_*`(kejilion) 和 `re/red/white`(ssh_tool) |
| 统计功能 | 默认关闭 | `ENABLE_STATS="false"`，尊重用户隐私 |
| 快捷命令 | `k` | 兼容两个项目的用户习惯 |
| 包管理 | kejilion的8种 | 支持apt/dnf/yum/apk/pacman/zypper/opkg/pkg |
| 配置文件路径 | `${SCRIPT_DIR}/config/` | 模块化后统一引用路径 |
| 菜单编号 | 1-20+00+88 | 整合kejilion(1-N)和ssh_tool(1-16+00+88) |

---

## 七、注意事项

1. **源文件仅用于核对**：模块入口已创建；复用上游代码前先确认许可、依赖和副作用。
2. **颜色变量兼容**：模块文件保留 `gl_*` 和 `re/red` 两套变量。
3. **系统操作需在目标发行版验证**：Windows Git Bash 的语法测试不能替代 Linux VPS 集成测试。
4. **在线执行风险**：旧脚本中存在上游在线脚本入口；执行前应核对内容与来源。

---

## 八、快速恢复指南

### 恢复工作的步骤

```bash
# 1. 检查项目当前状态
ls -la D:/ssh-toolbox/modules/

# 2. 运行模块语法及加载测试
bash tests/test_module_smoke.sh

# 3. Linux VPS 上逐项验证系统级功能前先阅读 README.md 和模块风险提示
```

### 模块编写参考

模块文件应只在被加载/调用时执行功能；交互菜单通过 `return` 返回调用方，不要递归进入主菜单：

```bash
#!/bin/bash
# ============================================================
# 模块: xxx (功能名称)
# 来源: kejilion.sh/ssh_tool.sh 的哪个选项/函数 (行号范围)
# 依赖: lib/common.sh (install, remove, break_end, main_menu, 颜色变量)
# ============================================================
xxx_menu() {
while true; do
    clear
    echo "▶ 功能名称"
    echo "------------------------"
    echo " 1. 选项1"
    echo " 2. 选项2"
    # ...
    echo -e "${skyblue} 0. 返回主菜单${re}"
    echo "------------------------"
    read -p "$(echo -e ${red}请输入你的选择: ${re})" sub_choice
    case $sub_choice in
        1) # ... 功能代码 ;;
        2) # ... 功能代码 ;;
        0) return 0 ;;
        *) echo "无效的输入!" ;;
    esac
    break_end
done
}
```

---

## 九、原项目信息

| 项目 | kejilion/sh | eooce/ssh_tool |
|------|------------|----------------|
| GitHub | https://github.com/kejilion/sh | https://github.com/eooce/ssh_tool |
| 版本 | v4.5.13 | v8.8.8 |
| Star | 3,481 | 795 |
| Fork | 1,057 | 290 |
| License | Apache 2.0 | 无(Fork) |
| 主脚本 | kejilion.sh (1.1MB) | ssh_tool.sh (283KB) |
| 创建时间 | 2023-05-08 | 2024-01-04 |
| 关系 | 上游仓库 | Fork of kejilion/sh |
| 作者 | 科技lion | 老王(eooce) |
