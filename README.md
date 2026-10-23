# SSH Toolbox

一个面向 Linux VPS 的 Bash 工具箱，整合常用系统管理功能及 `scripts/` 中的辅助脚本。项目当前采用按需 `source` 加载的模块结构。

## 运行要求

- Linux（Ubuntu、Debian、RHEL 系及 Alpine 等；各功能支持范围不同）
- Bash、curl、常见系统工具
- 系统管理功能通常需要 root 权限
- 修改系统或防火墙前请先备份，并确认云厂商控制台可用

## 使用

在每台有权限访问公开 GitHub 仓库的 Linux VPS 上，可直接下载并启动（安装到本地目录）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/testdogbot/ssh-toolbox/main/install.sh)
```

该入口会下载 `main` 分支并安装到 `/opt/ssh-toolbox`（使用 `sudo` 时）或 `~/.local/share/ssh-toolbox`，然后启动菜单。再次运行会更新由本安装器管理的目录，并保留上一版本备份。不要对已有但非本安装器管理的同名目录运行；安装器会拒绝覆盖。该方式依赖 VPS 能通过 HTTPS 访问 GitHub。

如果项目已经克隆到服务器，也可直接启动：

```bash
bash toolbox.sh
```

运行 `bash toolbox.sh --help` 查看命令帮助；只读命令（如 `info`、`docker ps`、`sshkey`）不要求 root。菜单、软件包管理、系统更新/清理、SSL 申请和系统修改操作需要 root。

支持的命令行入口包括 `info`、`update`、`clean`、`bbr3`、`docker`、`ssl`、`app`、`kpanel`、`fail2ban` 和 `sshkey`。

## 模块

- `modules/`：菜单功能，主入口按选择加载
- `lib/`：公共函数、语言和统计功能
- `scripts/`：独立的安装/管理辅助脚本
- `config/`：服务配置模板
- `apps/`：可选的本地应用脚本目录

部分上游安装器会更改系统配置或从网络获取代码。运行前请阅读对应脚本；LDNMP 安装脚本会重置 iptables 默认策略。KPanel 自动部署和系统重装入口目前明确不执行操作。

统计默认关闭（`ENABLE_STATS=false`），关闭时不会请求在线运行次数接口。系统语言环境不会被程序强行改写。快捷命令 `k` 和 `toolbox` 指向当前项目的 `toolbox.sh`，不会切换到其他上游脚本。

## 验证

```bash
bash tests/test_module_smoke.sh
```

该检查验证所有 Shell 文件语法，并确认主菜单引用的模块及入口函数可加载。

## 许可证

Apache License 2.0，详见 [LICENSE](./LICENSE)。部分辅助脚本来自其上游项目，使用前请核实各文件标注的来源和许可。
